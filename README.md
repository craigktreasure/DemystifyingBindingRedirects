# Demystifying Binding Redirects

## Description

Have you ever encountered an exception that looks something like this?

```text
Unhandled Exception: System.IO.FileLoadException:
Could not load file or assembly '<Some Name>, Version=<Some Version>, Culture=<...>, PublicKeyToken=<...>'
or one of its dependencies. The located assembly's manifest definition does not match the assembly
reference. (Exception from HRESULT: 0x80131040)
```

This tutorial will provide a comprehensive overview of binding redirects in .NET Framework applications. It will cover
the basics of what binding redirects are, when they are necessary, and how to use them. The training will also discuss
versioning of .NET assemblies, loading assemblies from other locations, binding redirects in other .NET runtimes such
as .NET Core and .NET 5+, and how to diagnose issues related to binding redirects. By the end of the training,
participants will have a solid understanding of binding redirects and how to use them effectively.

## Prerequisites

* This is an advanced topic that requires an understanding of .NET applications and the runtime.
* An understanding of the modern tools used to build and execute .NET applications.
* Windows
  * While the concepts demonstrated here are applicable to .NET Framework applications running on other platforms,
    the tutorial will assume you're using Windows.
* [.NET SDK 6.0+](https://dotnet.microsoft.com/download/dotnet/6.0)
* [NuGet Package Explorer](https://github.com/NuGetPackageExplorer/NuGetPackageExplorer)
* [ILSpy](https://github.com/icsharpcode/ILSpy)
* [PowerShell](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
  * [PowerShell 7.2+](https://github.com/PowerShell/PowerShell) is recommended.
* [AsmSpy](https://github.com/mikehadlow/AsmSpy)
  * Note that the version that comes with Chocolatey is old. Get the version from the ".zip" (NuGet package) instead.
  * Alternatively, you can run the [`scripts\SetupAsmSpy.ps1`](./scripts/SetupAsmSpy.ps1) script from PowerShell to
    download the package, extract it, and add it to the path for you.
* [Fusion++](https://github.com/awaescher/Fusion)
* [Visual Studio](https://visualstudio.com/)
  * Include the **.NET desktop development** workload.

## Outline

1. [Assembly versioning](./section1/README.md)
   1. How are .NET assemblies versioned?
   2. How to identify .NET assembly versions?
2. [How assemblies are loaded in a .NET Framework application](./section2/README.md)
   1. How are assemblies loaded?
   2. How can assembly load issues occur?
3. [Binding Redirects in .NET Framework applications](./section3/README.md)
   1. What are binding redirects and when are they necessary?
   2. How to apply a binding redirect?
   3. How to load an assembly from another location?
   4. Automatic binding redirects
4. [Diagnosing issues related to binding redirects](./section4/README.md)
   1. How to identify binding redirect related issues?
5. Binding Redirects in other .NET runtimes
   1. Are binding redirects necessary in .NET Core applications?

Start [here](./section1/README.md).
