# WFPのユーザー条件と同じDACLをメモリ内で検査する。OSのトークン・規則は変更しない。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
public static class TokenConditionProbe {
  [StructLayout(LayoutKind.Sequential)] public struct Mapping { public uint Read, Write, Execute, All; }
  [DllImport("advapi32.dll", SetLastError=true)] static extern bool IsTokenRestricted(IntPtr token);
  [DllImport("advapi32.dll", SetLastError=true)] static extern bool DuplicateToken(IntPtr token, int level, out IntPtr copy);
  [DllImport("advapi32.dll", SetLastError=true)] static extern bool GetTokenInformation(IntPtr token, int kind, IntPtr data, int length, out int needed);
  [DllImport("advapi32.dll", SetLastError=true)] static extern bool AccessCheck(byte[] sd, IntPtr token, uint access, ref Mapping map, IntPtr privileges, ref uint length, out uint granted, out bool allowed);
  [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr handle);
  static string[] RestrictedSids(IntPtr token) {
    int needed;
    GetTokenInformation(token, 11, IntPtr.Zero, 0, out needed);
    if (needed <= 0) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
    IntPtr buffer = Marshal.AllocHGlobal(needed);
    try {
      if (!GetTokenInformation(token, 11, buffer, needed, out needed)) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
      int count = Marshal.ReadInt32(buffer), offset = IntPtr.Size == 8 ? 8 : 4, stride = IntPtr.Size == 8 ? 16 : 8;
      var result = new List<string>();
      for (int i=0; i<count; i++) result.Add(new SecurityIdentifier(Marshal.ReadIntPtr(buffer, offset + i*stride)).Value);
      return result.ToArray();
    } finally { Marshal.FreeHGlobal(buffer); }
  }
  static object Check(IntPtr token, string sddl) {
    var sd = new RawSecurityDescriptor(sddl);
    byte[] bytes = new byte[sd.BinaryLength]; sd.GetBinaryForm(bytes, 0);
    IntPtr copy;
    if (!DuplicateToken(token, 2, out copy)) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
    IntPtr privileges = Marshal.AllocHGlobal(4096);
    try {
      uint length=4096, granted; bool allowed; var map=new Mapping {Read=1,Write=1,Execute=1,All=1};
      bool ok=AccessCheck(bytes,copy,1,ref map,privileges,ref length,out granted,out allowed);
      return new {sddl=sddl,apiSucceeded=ok,error=ok ? 0 : Marshal.GetLastWin32Error(),allowed=allowed,granted=granted};
    } finally { Marshal.FreeHGlobal(privileges); CloseHandle(copy); }
  }
  public static object Run() {
    using (var identity=WindowsIdentity.GetCurrent()) {
      var token=identity.Token; string user=identity.User.Value; string[] restricted=RestrictedSids(token);
      // AccessCheckにはowner/groupも必要。観測したWFPのDACLを保ち、メモリ内だけでgroupを補う。
      string userOnly="O:LSG:LSD:(A;;CC;;;"+user+")";
      string both=userOnly;
      foreach (string sid in restricted) both += "(A;;CC;;;"+sid+")";
      return new {userSid=user,isRestricted=IsTokenRestricted(token),restrictedSids=restricted,userOnly=Check(token,userOnly),userAndRestricted=Check(token,both),emptyDacl=Check(token,"O:LSG:LSD:")};
    }
  }
}
'@
[TokenConditionProbe]::Run() | ConvertTo-Json -Depth 8 -Compress
