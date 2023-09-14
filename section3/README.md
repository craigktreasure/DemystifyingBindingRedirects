# Binding Redirects in .NET Framework applications

- [Binding Redirects in .NET Framework applications](#binding-redirects-in-net-framework-applications)
  - [Part 1: Applying binding Redirects](#part-1-applying-binding-redirects)
    - [Other methods of applying binding redirects](#other-methods-of-applying-binding-redirects)
  - [Part 2: Loading assemblies from another location](#part-2-loading-assemblies-from-another-location)
    - [Load using a codeBase element](#load-using-a-codebase-element)
    - [Load using a probing element](#load-using-a-probing-element)
  - [Part 3: Automatic binding redirects](#part-3-automatic-binding-redirects)
  - [FAQ](#faq)
  - [Next Steps](#next-steps)
  - [Resources](#resources)

In this section, we'll lean the following:

- What are binding redirects and when are they necessary?
- How to apply a binding redirect?
- How to configure the runtime to load assemblies from different locations?
- What are automatic binding redirects?

**Keep in mind** that the details discussed below are specific to .NET Framework applications and libraries. The
behavior of modern .NET 5+ (and .NET Core) runtimes and applications are quite different. We'll discuss some of these
differences in a later section.

Make sure you have installed the [prerequisites](../README.md#prerequisites) before beginning.

## Part 1: Applying binding Redirects

A binding redirect instructs the .NET Runtime to use a different version of an assembly than what it referenced at
compile time.

You might ask, "why would this ever be necessary if the application is always accompanied by the assemblies it was
compiled with?" Well, in that case, it wouldn't. For any number of reasons, it may be desirable to execute an
application with a different version of an assembly.

There really are many reasons, but some examples are:

- You don't have control over all or some of the dependencies that will be deployed where the application will run.
- You can't recompile the application and need to make it work with a different assembly version.

Building on our example from [Section 2][section-2], let's see if we can fix the issue using an application
configuration file.

> **Note:**
>
> Except for the name of the application, files, and namespace, the project in this directory is exactly the same as
> the one we used previously in [Section 2][section-2].

In PowerShell, navigate to this directory and run the [Simulate.ps1][simulate-script] script again to verify the current
state of the application by running `.\Simulate.ps1 -RunApp -SwitchDependency`. The output, which you should recognize
from [Section 2][section-2], should be:

```text
~\repos\DemystifyingBindingRedirects\section3> .\Simulate.ps1 -RunApp -SwitchDependency
Publishing the application...
MSBuild version 17.3.2+561848881 for .NET
  Determining projects to restore...
  Restored C:\Users\me\repos\DemystifyingBindingRedirects\section3\Section3.csproj (in 213 ms).
  Section3 -> C:\Users\me\repos\DemystifyingBindingRedirects\section3\bin\Debug\net472\Section3.exe
  Section3 -> C:\Users\me\repos\DemystifyingBindingRedirects\section3\bin\Debug\net472\publish\
Switching the dependency...
Downloading newer dependency...
Extracting the dependency...
Overwriting the dependency from package version 12.0.3 with 13.0.3...
Running the application...
Web request status [Web request completed. (Number of bytes processed: 2441966)                                      ]
Unhandled Exception: System.IO.FileLoadException: Could not load file or assembly 'Newtonsoft.Json, Version=12.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed' or one of its dependencies. The located assembly's manifest definition does not match the assembly reference. (Exception from HRESULT: 0x80131040)
```

Let's try using an [application configuration file][appconfig] to fix the issue. Create a new file in this folder
called `App.config` containing the following content:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <runtime>
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
      <dependentAssembly>
        <assemblyIdentity name="Newtonsoft.Json" publicKeyToken="30ad4fe6b2a6aeed" culture="neutral" />
        <bindingRedirect oldVersion="12.0.0.0" newVersion="13.0.0.0" />
      </dependentAssembly>
    </assemblyBinding>
  </runtime>
</configuration>
```

> **Note:**
>
> Modern .NET projects publish an `App.config` file to the output by default when one is present. Some projects may
> disable this behavior requiring you to configure the project to include the file in the output.

Let's examine and explain the content of this file a bit before we test it out.

The `assemblyBinding` element and its contents are the relevant parts.

| Attribute Name   | Description                                                                |
|------------------|----------------------------------------------------------------------------|
| `name`           | The assembly name.                                                         |
| `publicKeyToken` | The public key for the assembly, which comes from the key used to sign it. |
| `culture`        | The culture associated with the assembly.                                  |

These values are all used to uniquely identify the assembly. These details can be found in the [ILSpy][ilspy] output of
the assembly as well as the [asmspy][asmspy] output:

```text
Newtonsoft.Json, Version=12.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed
Newtonsoft.Json, Version=13.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed
```

Now, let's take a look at the `bindingRedirect` element.

| Attribute Name | Description                                                                                                            |
|----------------|------------------------------------------------------------------------------------------------------------------------|
| `oldVersion`   | Either a single version or a version range and indicates the version (or versions) for which the the redirect applies. |
| `newVersion`   | A single version which indicates the new expected version.                                                             |

Based on our understanding of what's happening, we specify `12.0.0.0` for `oldVersion` and `13.0.0.0` for `newVersion`.
We could just as easily specify something like `0.0.0.0-12.0.0.0` or `0.0.0.0-99.0.0.0` for the `oldVersion` to be more
flexible.

Now, let's run the [Simulate.ps1][simulate-script] again to execute the application again, but this time it will
include our binding redirects. In PowerShell, run `.\Simulate.ps1 -RunApp -SwitchDependency`.

Hey! This time, things appear to be working! You'll also notice that, while the files aren't exactly the same, the
binding redirect we configured in `App.config` was included in the `Section3.exe.config` file that was deployed.

The side effect of this is that we have now broken the case where the application is deployed or executed with any
other version of the assembly, like `12.0.0.0`. We can demonstrate this by running `.\Simulate.ps1 -RunApp` without the
`-SwitchDependency` parameter, which will not replace the `Newtonsoft.Json` assembly with the `13.0.0.0` version.

The application, when executed with `Newtonsoft.Json` version `12.0.0.0`, now throws the following exception:

```text
Unhandled Exception: System.IO.FileLoadException: Could not load file or assembly 'Newtonsoft.Json, Version=13.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed' or one of its dependencies. The located assembly's manifest definition does not match the assembly reference. (Exception from HRESULT: 0x80131040) ---> System.IO.FileLoadException: Could not load file or assembly 'Newtonsoft.Json, Version=12.0.0.0, Culture=neutral, PublicKeyToken=30ad4fe6b2a6aeed' or one of its dependencies. The located assembly's manifest definition does not match the assembly reference. (Exception from HRESULT: 0x80131040)
   --- End of inner exception stack trace ---
   at Section2.Program.Main(String[] args)
```

It's the opposite of the previous exception we saw without the binding redirect. It now wants version `13.0.0.0` of
`Newtonsoft.Json`, but found `12.0.0.0`. If we refer back to what we learned about how assemblies are loaded in
[Section 2](../section2/README.md#part-1-assembly-loading), this makes sense as we have used a configuration file to
override the expected version to `13.0.0.0`. Version `12.0.0.0` of `Newtonsoft.Json` is no longer considered valid.

> **Note:**
>
> The `asmspy` tool (as of version `1.3.136`) doesn't properly consider binding redirects even when specified using the
> `--configurationFile` parameter.

### Other methods of applying binding redirects

We won't cover other methods here, but there are a few other methods of applying binding redirects:

- [Publisher Policy File][publisherpolicy]
- [Machine Configuration File][machineconfig]

## Part 2: Loading assemblies from another location

Now, let's say, for example, that we don't want to change the assembly version and would instead like to load the
dependency from a different location. We can instruct the .NET Framework runtime to load the assembly from a different
location using a few different methods.

This scenario is a bit complicated, so let's break it down a bit more. The project will still require version `12.0.0.0`
of `Newtonsoft.Json`. But, version `13.0.0.0` will still be in the same folder as the application, which was previously
problematic. Remember, we're pretending that we don't have control over that version of the assembly. This time, we're
going to copy the `12.0.0.0` version of the assembly to an `old` subfolder in the output and instruct the runtime to
look in that location for the assembly instead.

| File                                               | Assembly Version |
|----------------------------------------------------|------------------|
| `bin\Debug\net472\publish\Section3.exe`            | `1.0.0.0`        |
| `bin\Debug\net472\publish\Section3.exe.config`     | NA               |
| `bin\Debug\net472\publish\Newtonsoft.Json.dll`     | `13.0.0.0`       |
| `bin\Debug\net472\publish\old\Newtonsoft.Json.dll` | `12.0.0.0`       |

### Load using a codeBase element

Let's first start by using the `codeBase` element method. Adjust the contents of the `App.config` file to look like the
following:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <runtime>
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
      <dependentAssembly>
        <assemblyIdentity name="Newtonsoft.Json" publicKeyToken="30ad4fe6b2a6aeed" culture="neutral" />
        <codeBase version="12.0.0.0" href="old\Newtonsoft.Json.dll" />
      </dependentAssembly>
    </assemblyBinding>
  </runtime>
</configuration>
```

Note how the `bindingRedirect` element has been replaced with a `codeBase` element configured with the `href`
attribute value set to  `old\Newtonsoft.Json.dll`. This instructs the runtime to look for assembly version `12.0.0.0`
at `old\Newtonsoft.Json.dll` relative to the application base path or, in this case, where the `exe` resides.

The [Simulate.ps1][simulate-script] has an additional parameter called `-KeepOldDependency`, which will cause version
`12.0.0.0` of the assembly to be copied to the `bin\Debug\net472\publish\old` folder to match our scenario. In
PowerShell, run `.\Simulate.ps1 -RunApp -SwitchDependency -KeepOldDependency`.

Now, you can see that the application runs without a binding redirect, but instead loads the assembly from a different
location.

You can learn more about the details of using the `codeBase` element to load assemblies in the
[documentation][assembly-location-codebase] and further details in [Step 4][locating-assembly-step4] of "How the Runtime
Locates Assemblies".

### Load using a probing element

Next, let's try using the `probing` element method. Adjust the contents of the `App.config` file to look like the
following:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <runtime>
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
      <probing privatePath="old" />
    </assemblyBinding>
  </runtime>
</configuration>
```

Note how the `dependentAssembly` element has been replaced with a `probing` element configured with the `privatePath`
attribute value set to `old`. This instructs the runtime to first look in a folder called `old` for any assemblies it
needs to load. That folder path is relative to the application base path or, in this case, where the `exe` resides.

Again, using the [Simulate.ps1][simulate-script] script's `-KeepOldDependency` parameter, which will cause version
`12.0.0.0` of the assembly to be copied to the `bin\Debug\net472\publish\old` folder to match our scenario. In
PowerShell, run `.\Simulate.ps1 -RunApp -SwitchDependency -KeepOldDependency`.

Now, you can see that the application runs without a binding redirect, but instead loads the assembly from a different
location.

A downside could be that you cannot scope the probing to a specific assembly. Since the runtime will now first check the
probing folder for any assemblies it needs to load, there could be a problem if there were other conflicting assemblies
in the `old` folder.

You can learn more about the details of using the `probing` element to load assemblies in the
[documentation][assembly-location-probing] and further details in [Step 4][locating-assembly-step4] of "How the Runtime
Locates Assemblies".

## Part 3: Automatic binding redirects

By the name, you might be lured into thinking that a feature called "Automatic binding redirects" will solve all your
problems. Well, it won't. In fact, it is enabled by default in desktop apps targeting .NET Framework 4.5.1+. Which
means that it was already enabled for our example from [Section 2][section-2] and in
[Part 1](#part-1-applying-binding-redirects). Automatic binding redirects are best described [here][auto-br], but are
essentially used to automatically add binding redirects at compile time when there are conflicting versions of an
assembly being referenced either by the project directly or by its dependencies.

Also, automatic binding redirects do not work for web projects using `Web.config`. Instead, there is a feature in
Visual Studio that attempts to help you configure binding redirects when conflicts are detected.

## FAQ

**Q:** Can you specify multiple `bindingRedirect` elements for a single assembly?

**A:** Yes. You can specify multiple `bindingRedirect` elements for a single assembly. This can be useful when sharing
       an application configuration file where different versions are used and deployed. For example, let's say you
       wanted to configure a binding redirect to always redirect to a newer version, but keeping within the same major
       version of the assembly. You could do something similar to:

```xml
...
      <dependentAssembly>
        <assemblyIdentity name="Foo.Assembly" publicKeyToken="aaaaaaaaaaa" culture="neutral" />
        <bindingRedirect oldVersion="1.0.0.0-1.99.99.99" newVersion="1.0.0.4" />
        <bindingRedirect oldVersion="2.0.0.0-2.99.99.99" newVersion="2.0.0.5" />
      </dependentAssembly>
...
```

**Q:** Which `newVersion` is used when multiple `bindingRedirect` elements using the same `oldVersion` are specified?

**A:** The first one is used. For example:

```xml
      <dependentAssembly>
        <assemblyIdentity name="Newtonsoft.Json" publicKeyToken="30ad4fe6b2a6aeed" culture="neutral" />
        <bindingRedirect oldVersion="12.0.0.0" newVersion="13.0.0.0" />
        <bindingRedirect oldVersion="12.0.0.0" newVersion="14.0.0.0" />
      </dependentAssembly>
```

Assembly version `13.0.0.0` will be expected and `14.0.0.0` will be ignored.

**Q:** The example we used performed an upgrade to use a newer assembly version. Can you perform downgrades using
       binding redirects?

**A:** Yes, but with the same risks as performing upgrades.

**Q:** Are there any downsides to the use of binding redirects?

**A:** While binding redirects are sometimes the only solution, there are some risks. Such as:

- The version of the assembly you are instructing the application to use isn't what it was compiled with. If an API
  the application depends on was removed or modified, you'll get a runtime error if you're lucky, but it could also
  result in unexpected behavior. If an API used to return "a", but now returns "aa" and the application code wasn't
  expecting that, the application might behave in an unexpected way. These issues can be difficult to debug.

## Next Steps

Continue the tutorial in [Section 4](../section4/README.md).

## Resources

- [Automatic Binding Redirection][auto-br]
- [How the Runtime Locates Assemblies][runtime-assembly-loading]
- [Nick Craver on Binding Redirects][nick-craver-br]
- [Redirecting assembly versions][redirecting-assembly-versions]
- [Step 4: Locating the Assembly through Codebases or Probing][locating-assembly-step4]
- [Understanding How Assemblies Load in C# .NET][understanding-how-assemblies-load]

[appconfig]: https://learn.microsoft.com/dotnet/framework/deployment/how-the-runtime-locates-assemblies#application-configuration-file "Application COnfiguration File"
[assembly-location-codebase]: https://learn.microsoft.com/dotnet/framework/configure-apps/specify-assembly-location#using-the-codebase-element "Using the <codeBase> Element"
[assembly-location-probing]: https://learn.microsoft.com/dotnet/framework/configure-apps/specify-assembly-location#using-the-probing-element "Using the <probing> Element"
[asmspy]: https://github.com/mikehadlow/AsmSpy "AsmSpy"
[auto-br]: https://learn.microsoft.com/dotnet/framework/configure-apps/redirect-assembly-versions#rely-on-automatic-binding-redirection "Automatic binding redirection"
[ilspy]: https://github.com/icsharpcode/ILSpy "ILSpy"
[locating-assembly-step4]: https://learn.microsoft.com/dotnet/framework/deployment/how-the-runtime-locates-assemblies#step-4-locating-the-assembly-through-codebases-or-probing "Step 4: Locating the Assembly through Codebases or Probing"
[machineconfig]: https://learn.microsoft.com/dotnet/framework/deployment/how-the-runtime-locates-assemblies#machine-configuration-file "Machine Configuration File"
[nick-craver-br]: https://nickcraver.com/blog/2020/02/11/binding-redirects/ "Binding Redirects"
[publisherpolicy]: https://learn.microsoft.com/dotnet/framework/deployment/how-the-runtime-locates-assemblies#publisher-policy-file "Publisher Policy File"
[redirecting-assembly-versions]: https://learn.microsoft.com/dotnet/framework/configure-apps/redirect-assembly-versions "Redirecting assembly versions"
[runtime-assembly-loading]: https://learn.microsoft.com/dotnet/framework/deployment/how-the-runtime-locates-assemblies "How the Runtime Locates Assemblies"
[section-2]: ..\section2\README.md "Section 2"
[simulate-script]: .\Simulate.ps1 "Simulate.ps1"
[understanding-how-assemblies-load]: https://michaelscodingspot.com/assemblies-load-in-dotnet/ "Understanding How Assemblies Load in C# .NET"
