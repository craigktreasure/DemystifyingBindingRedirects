# How assemblies are loaded in a .NET Framework application

- [How assemblies are loaded in a .NET Framework application](#how-assemblies-are-loaded-in-a-net-framework-application)
  - [Part 1: Assembly loading](#part-1-assembly-loading)
  - [Part 2: A practical example of an assembly load issue](#part-2-a-practical-example-of-an-assembly-load-issue)
  - [Next Steps](#next-steps)
  - [Resources](#resources)

In this section, we'll lean the following:

- How does the .NET Framework runtime load assemblies?
- What can cause assembly load issues to occur?

**Keep in mind** that the details discussed below are specific to .NET Framework applications and libraries. The
behavior of modern .NET 5+ (and .NET Core) runtimes and applications are quite different. We'll discuss some of these
differences in a later section.

Make sure you have installed the [prerequisites](../README.md#prerequisites) before beginning.

## Part 1: Assembly loading

When the .NET Runtime needs to load an assembly, it goes through a
[well documented process][runtime-assembly-loading]. Most of the time, you don't need to worry about this process.
But when an application fails to load an assembly, it plays a vital role to understand where an assembly is getting
loaded from.

Essentially:

1. Determine what version of an assembly needs to be loaded.
   1. This is a combination of the assembly version referenced when the assembly was built and any configuration files
      available (`app.config` or `web.config` for example).
2. Check if the assembly has already been loaded. If a different version has already been loaded, fail immediately.
3. Check the [Global Assembly Cache][gac] (or GAC for short) for the assembly.
4. Probe other locations for the assembly.
   1. Application base directory.
   2. Known directories within the application base directory.
   3. Locations denoted in configuration files, such as by the use of the `codeBase` element or the `privatePath`
      attribute.

For a more comprehensive explanation, see [How the Runtime Locates Assemblies][runtime-assembly-loading].

## Part 2: A practical example of an assembly load issue

Let's consider, as an example, that your're building and deploying an application where you don't have control over all
of the assemblies that are deployed.

Open the `Section2.csproj` file in a text editor and examine it. It is a bit different from the previous section.
What's important is that the project now references `Newtonsoft.Json` package version `12.0.3`. If we were to open
the assembly in [ILSpy][ilspy] after it is compiled, you would find that it references `Newtonsoft.Json` with assembly
version `12.0.0.0`. Now, let's say that the deployment system is going to demand a newer version and your deployed
output ends up with a newer version: `13.0.0.0`.

We can simulate this experience using the [`Simulate.ps1`][simulate-script] script. The script will first build and publish the
application by running `dotnet publish -c Debug`. Specifying the `-SwitchDependency` parameter will download
`Newtonsoft.Json` package version `13.0.3`, extract the package, and swap the `Newtonsoft.Json.dll` file in the
published output with the newer version from the package to simulate having a newer version deployed to the output. Lastly, specifying the `-RunApp` parameter will execute the application directly from the published output location.

First, let's test the application in a working state with all of the expected dependencies in place. In PowerShell,
navigate to the `/section2` folder of this repository and run: `.\Simulate.ps1 -RunApp`.

You should see something similar to the following output:

```text
~\repos\DemystifyingBindingRedirects\section2> .\Simulate.ps1 -RunApp
Cleaning the publish output folder...
Publishing the application...
MSBuild version 17.3.2+561848881 for .NET
  Determining projects to restore...
  All projects are up-to-date for restore.
  Section2 -> C:\Users\me\repos\DemystifyingBindingRedirects\section2\bin\Debug\net472\Section2.exe
  Section2 -> C:\Users\me\repos\DemystifyingBindingRedirects\section2\bin\Debug\net472\publish\
Running the application...
["Hello","World!"]
```

Now, let's run the script again with the `-SwitchDependency` parameter: `.\Simulate.ps1 -RunApp -SwitchDependency`.

Note the difference in the output:

```text
~\repos\DemystifyingBindingRedirects\section2> .\Simulate.ps1 -RunApp -SwitchDependency
Cleaning the publish output folder...
Publishing the application...
MSBuild version 17.3.2+561848881 for .NET
  Determining projects to restore...
  All projects are up-to-date for restore.
  Section2 -> C:\Users\me\repos\DemystifyingBindingRedirects\section2\bin\Debug\net472\Section2.exe
  Section2 -> C:\Users\me\repos\DemystifyingBindingRedirects\section2\bin\Debug\net472\publish\
Switching the dependency...
Downloading newer dependency...
Web request status [Web request completed. (Number of bytes processed: 2441966)                                      ]
Extracting the dependency...
Overwriting the dependency from package version 12.0.3 with 13.0.3...
Running the application...
Unhandled Exception: System.IO.FileLoadException: Could not load file or assembly 'Newtonsoft.Json, Version=12.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed' or one of its dependencies. The located assembly's manifest definition does not match the assembly reference. (Exception from HRESULT: 0x80131040)
```

It wasn't able to locate assembly version `12.0.0.0` of `Newtonsoft.Json`. This makes sense since the script replaced
it with a newer version: `13.0.0.0`. The version number the runtime found doesn't match the assembly's manifest, so a
`System.IO.FileLoadException` is thrown.

```text
Unhandled Exception: System.IO.FileLoadException:
Could not load file or assembly 'Newtonsoft.Json, Version=12.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed'
or one of its dependencies. The located assembly's manifest definition does not match the assembly reference.
(Exception from HRESULT: 0x80131040)
```

You can inspect the assemblies yourself to confirm the problem by opening the assemblies located at `bin/Debug/net472/publish` in [ILSpy][ilspy]. Alternatively, you can use another helpful tool called [AsmSpy][asmspy] to do the work for you.

After setting up the `asmspy` tool (see the [prerequisites](../README.md#prerequisites) for help), run `asmspy .\bin\Debug\net472\publish\Section2.exe --nonsystem`.

You should see output similar to the following:

```text
~\repos\DemystifyingBindingRedirects\section2> asmspy .\bin\Debug\net472\publish\Section2.exe --nonsystem
Root assembly specified: 'Section2.exe'
Checking for local assemblies in: '.\bin\Debug\net472\publish', TopDirectoryOnly
File Newtonsoft.Json.dll => Newtonsoft.Json 13.0.0.0
File Section2.exe => Section2 1.0.0.0
Found different version reference Newtonsoft.Json, requested: 12.0.0.0-> found: 13.0.0.0
Root: Section2
Detailing only conflicting assembly references.
Reference: Newtonsoft.Json, Version=12.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed
  Newtonsoft.Json, Version=13.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed
Source: NotFound (AlternativeVersionFound)
    12.0.0.0 by Section2, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null
```

The output shows that `asmspy` indeed detected the issue and indicates that it found a different version of
`Newtonsoft.Json`.

There are a few options for resolving this issue and each has tradeoffs depending on the situation:

- Recompile the application with the expected version of the `Newtonsoft.Json`.
  - In general, this option is preferred as it allows you to validate the application using tests with the version of
    the assembly that it would be deployed with.
- Use Binding Redirects to allow the runtime to load the unexpected assembly version.
  - Useful when you either can't re-compile the application or you don't control the dependencies on which the
    application runs.

## Next Steps

Continue the tutorial in [Section 3](../section3/README.md).

## Resources

- [How the Runtime Locates Assemblies][runtime-assembly-loading]
- [Understanding How Assemblies Load in C# .NET][understanding-how-assemblies-load]

[asmspy]: https://github.com/mikehadlow/AsmSpy "AsmSpy"
[gac]: https://learn.microsoft.com/dotnet/framework/app-domains/gac "Global Assembly Cache"
[ilspy]: https://github.com/icsharpcode/ILSpy "ILSpy"
[runtime-assembly-loading]: https://learn.microsoft.com/dotnet/framework/deployment/how-the-runtime-locates-assemblies "How the Runtime Locates Assemblies"
[simulate-script]: .\Simulate.ps1 "Simulate.ps1"
[understanding-how-assemblies-load]: https://michaelscodingspot.com/assemblies-load-in-dotnet/ "Understanding How Assemblies Load in C# .NET"
