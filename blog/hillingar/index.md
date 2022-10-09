---
pagetitle: "Hillingar | gibbr.org"
date: "2022-08-27 00:00:00"
---
# Hillingar

> An arctic mirage [^0]

[^0]: [W. H. Lehn, ‘The Novaya Zemlya effect: An arctic mirage’, J. Opt. Soc. Am., JOSA, vol. 69, no. 5, pp. 776–781, May 1979, doi: 10.1364/JOSA.69.000776](https://home.cc.umanitoba.ca/~lehn/_Papers_for_Download/NZ79.pdf).

As part of my masters thesis I've been hosting an authoritative DNS server at `ns1.gibbr.org`.
And as part of my masters thesis procrastination, I've been running it on a NixOS [^1] machine.
Deploying a DNS server using NixOS is as simple as:
```nix
services.bind = {
  enable = true;
  zones."gibbr.org" = {
    master = true;
    file = "gibbr.org.zone";
  };
};
```

[^1]: [nixos.org](https://nixos.org)

As you might notice, however, this is running the venerable bind written in C.
Instead, using functional high-level type-safe programming languages to create network applications can greatly benefit safety and usability whilst maintaining performant execution [^2].
One such language is OCaml.

[^2]: https://anil.recoil.org/papers/2007-eurosys-melange.pdf

The MirageOS project is a deployment method for these OCaml programs [^3].
Instead of running them as a traditional Unix process, we instead create a specialised 'unikernel' operating system to run the application which allows dead code elimination improving security with smaller attack surfaces, and improved efficiency.

[^3]: https://anil.recoil.org/papers/2013-asplos-mirage.pdf

However, to deploy a Mirage unikernel on NixOS one has to use the imperative deployment methodologies native to the OCaml ecosystem with tools such as `opam` and `dune`, eliminating the benefit of reproducible systems that Nix gives us.
This blog post will explore how we enabled reproducible deployments of Mirage unikernels with Nix.

# Nix

At this point the curious reader might be wondering, what on earth is 'NixOS'.
To understand NixOS, we first have to understand the deployment system it was build on: Nix.

![](./nix-snowflake.svg){width=60% min-width=5cm}

Nix was created as a deployment system to 



Nix Nix is a lazy functional language for building software.
To build software, at the most basic level we invoke a compiler to turn some code to some other code.
This could be turning C code into machine code, or Java source code to JVM bytecode.
Software often has dependencies on external libraries, files, and other parts of your operating system; dependencies which can be explicit or implicit.
Even the compiler, being code itself, is a dependency.
Nix, by default, gives us sandboxes builds in isolation so all dependencies - implicit or explicit - are captured, to ensure reproducibility.


// Nix tech details to build a vocabulary

Nix

DSL

nix store

nixpkgs

NixOS


I guess the most caveman way of doing, that would be going to a URL on the internet, downloading the source code or the binary. If it's the source code, it's compiling that and like getting the dependencies manually and running it through some scripts and configuring it through some random scripts too.

A build can't access things outside in the wider file system or have network access. If all the inputs 
These build rules with specific inputs are called 'deriviations'.

Projects often reply on interacting with system or language package managers to make sure all the build and runtime dependencies are available. Projects may implicitly rely on system configuration at build or runtime. Even using a different compiler version may likely result in a different binary.




Nix tries to minimise global mutable state that without knowing it you might reply on being set up in a certain way. The benefit you get from Nix is that you're forced to encode this in a reproducibile way, but that can also be frustrating at times because it can make it harder to get off the ground. pinning all inputs, in the absence of any non-determinism at build time guaranteing reproducibility.

What is a derivation? Here

There's analogies to functional program verses imperative programming, but applied to system management and software builds/deployment.

It also has some other benefits - you can upgrade software atomically. If things go badly you can easily revert because software isn't actually installed on your system - symlinks are created into the immutable (read only) `/nix/store`. With packages stored at a path of the hash of their inputs. The

Nix build managers build time config management, but not runtime

Minimising  global mutable state



#### Nixpkgs


With the Nix language a huge number of derivations have been created to package software with Nix.

Nixpkgs

big monorepo [^4]

[^4]; [https://discourse.nixos.org/t/nixpkgss-current-development-workflow-is-not-sustainable/18741](https://discourse.nixos.org/t/nixpkgss-current-development-workflow-is-not-sustainable/18741)

source based, but
binary cache for sharing build results




#### NixOS

On top of this is build NixOS - an OS that uses the Nix language to manage the system configuration.

That's really neat because traditionally this is just done through like random command line things and maybe you do something and forget how to do it and you can't repeat it for another machine easily or even, just like using someone else's software.

If you want to deploy some software it can be as easy as changing a line in your system configuration.



The reason I actually switched was because Arch kept breaking on my.
(no partial upgrades and manual rollbacks from pacman cache)


But the tipping point was I was upgrading my laptop and it crashed or shut down or lost some powers or something and then the kernel was like, it was upgrading the kernel and that's like the most basic part of the machine. I that crashed during that. So like the kernel was malfarmed so I had to reinstall the kernel which is just not something you ought to do when you have a deadline or something so that like atomic upgrades and rollback rollback ability ability to evacuation systems.

GRUB stuff



source based
- w/o binary cache it's like gentoo




Instead of trying to describe Nix from scratch I'll instead point you in the direction of the excellent blog post 'Nix – taming Unix with functional programming' by Valentin Gagarin at Tweag [^5].

[^5]: [https://www.tweag.io/blog/2022-07-14-taming-unix-with-nix/](https://www.tweag.io/blog/2022-07-14-taming-unix-with-nix/)

Nix wra


If any of the detivtion's inputs change, the hash will change, and the path will change. So this.captures deep traces of inputs (as each input is also a deticaiton with a hash base on its inputs).

Using Nix and Nixpkgs, this approach has been extended to manage an entire Linux operating system.
Nixos
System configurations



While Mirage was part of my masters thesis, Nix was part of my masters thesis procrastination.

Nix is a declarative, functional, language for describing a system configuration.
reproducible

It was good supprt for derivations... 

to install a package you write a Nix expression that descibes a system with that pakage instaled

// ecosystem

![](./nix-stack.svg){width=50% min-width=5cm}


other things:
store
DSL
hydra
NixOps

package manager (command line tool)

#### Flakes

// flakes

We also use Nix flakes for this project.
Without going into too much depth, for our purposes they provide a nice way to compose Nix projects.
More detail can be read at a series of blog posts by Eelco on the topic [^7].

[^7]: https://www.tweag.io/blog/2020-05-25-flakes/



### Deploying unikernels

Why couldn't we just write a NixOS module to deploy a unikernel?
Well, first we need to support building unikernels with Nix.
This blog post will explore how to do that to provide easy deployability of Mirage unikernels.

### MirageOS

![](./mirage.svg){width=50% min-width=5cm}


// what?
What on earth is a unikernel I hear you cry?

A unikernel is a operating system kernel that contains low level operating system code and high level application code bundled into one.
There is no kernel or user space - they are one and the same.

Puts all of the code like in one big blob and then it's all secure and safe. And you can remove a bunch of dead codes because there's no interface between the application and the open on the operating system. There's no interface between the application and the operating system has been fine.

### OCaml

Mirage is written in OCaml.

OCaml is a functional programming language, but it a bit more practical than others (like haskell) supporting imperative programming too.





is a small perfor

Mirage was the first 'unikernel' creation framework, but it comes from a long linage of OS OS research such as the library OS nemesis (?)

// why?


security, performance, speed

it's quite good for networking or highly networked applications as these tend to be quite performant and security concious.

It was originally created to run on hypervisors in the cloud.
But there is work towards porting it to run on bare metal for IoT applications.
But hw support tricky.











### Building unikernels

NixOS modules
https://github.com/NixOS/nixpkgs/blob/fe76645aaf2fac3baaa2813fd0089930689c53b5/nixos/modules/services/networking/bind.nix

https://nixos.wiki/wiki/NixOS_modules


So Mirage is this thing.
It's written in OCaml and uses all the OCaml tooling.
In fact a lot of that tooling, like opam, was created for the Mirage project.
But this is weird-ish (opam switches - like python venvs), and sometimes tricky to newcomers who are not familar with the ecosystem.

Let's say you just want to deploy a unikernel for all the benefits we described but you aren't don't want to deal with building and deploying it.
Enter Nix: Nix is a really nice story for deploying these unikernels.
I someone's familar with Nix, which seems to be growing in popularitym, moreso than Mirage, it makes it really easy to deploy them (as it's focusd on deploying software in general).

But there's no kind of support for this at the moment.


types of deps:
- system
- library
- project
we will be built in the host compiler, and some will be built in the target compiler. So, a concept that came up with was like, system dependencies, library, dependencies and project dependencies.




Nix is really good system dependencies. Opam is really good at the library dependencies.
Opam kind of tries the system dependencies but not on a very reproducible way.
Nix tries the library dependencies but it doesn't have a way of like resolving different versions nicely.
As this huge issues shows:
https://github.com/NixOS/nixpkgs/issues/9682
Nixpkgs has one global coherent package set.
In fact arch has the same approach which is why it doesn't support partial upgrades.
This isn't an issue when your projects can point different dependencies in the Nix store.
It allows installing different versions of the same package because it symlinks everything.
But when you're linking a binary this doesn't work.
It could be interesting to link a binary using different versions of the same package (preprending signatures with versions, say).


Nix doesn't do version resolution

use opam to do that
0install solver
NP hard problem?


There is an `opam-nix` project which ports opam projects to Nix.
But it doesn't have the support for what we need.
The Mirage unikernels quite often need to be cross-compiled: compiled to run on a machine other than the machine you're building it on.
A target they use is solo5, which isn't a different mircoarchitecture, but it uses a difrert GLIBC which requires cross compilation.
However, PPX is a library that runs some code to generate other code, which doesn't work in a cross compilation context.
The OCaml compiler does not support cross compilation.
// TODO find link
But Dune, the build system does.
But opam has no concept to cross compilation.
So the cross compilation information is included in the build system instructions like pre-processed this particular module in the host compiler, as oppsed to the target compiler.
Which is something Dune has - a tool chin which has a target compiler embedded in it, which is modified from the host compiler.
That's a bit tricky because it means we need to get all of the sources for the dependencies because we don't know in advance what context they're going to need to be built in?
I think it could be interesting to try and encode this in the package manager.
Like this this particular module will be will built for the host compiler or the target compiler.
But the tricky thing is some dependencies have modules which will be built in the host compiler, and some in the target compiler.
We're conflating the library and project deps here, because we need the cross compilation context in the package manager, but the package manager only has a concept of packages - and not modules - inside a project or dependancy.
You can have multiple packages inside of development repository, and then multiple modules inside one package.
It's kind of messy - there's no one cohesive vision.


opam-monorepo:
> -   Cross-compilation - the details of how to build some native code can come late in the pipeline, which isn't a problem if the sources are available




Lucas has a vision of resolving dependencies by interface types rather than numerical versions...




The way Mirage 4 works is - opam monorepo workflow.
Gets all sources locally for cross compilation.
So what we did was add support for this to `opam-nix`
github.com/RyanGibb/hillingar
And create a project `hillingar` which wraps the Mirage tools in Nix.
github.com/RyanGibb/hillingar
// TODO what does hillingar mean?
As opposed to wrapping Nix in Mirage tools.
Interesting arguments both ways - the former is better for Nix-natives and the latter better for OCaml/Mirage natives.
But this way the most sensible for me, and easiest to prototype (no PRs).
Also, it enables us to deploy unikernels using Nix.

I guess my contribution was like a relatively modest PR to this open next conversion project.
But there was like so much work to go into that like understanding what was going on and figuring out all these weird edge cases and stuff.
So let me give you the summary.
I was extending some support for an existing library to build in this workflow required for the unikernels.


drawbacks:
-


what are the benefits?:
- 


### Conclusion

Nix and Mirage
both brining some kind of functional paradigm to OSes
but top down vs bottom up



Future work:
- github.com/RyanGibb/hillingar
- system config is nice
	- NixOS module

relevant work:
https://mirage.io/blog/deploying-mirageos-robur
Nix is source based...
could deploy binaries with a binary cache
as long as, e.g. zonefile, is not part of the build

reproducible builds:
https://hannes.nqsb.io/Posts/ReproducibleOPAM
https://robur.coop/Projects/Reproducible_builds

work on deploying them:
https://hannes.robur.coop/Posts/VMM




thanks to:
- Lucas for OCaml ecosystem
- Balsoft for getting me to speed with the `opam-nix` project and working with me on the opam monorepo workflow integration
- Anil for proposing the project
- bjorg for icelandic language consulting


This worked was completed as part of an internship with Tarides. A copy of this blog post can be found on Tarides website.

---

Opam2nix
Depends on binary of itself at build time: not very Nixy
Not as minimal - (LOC stats) probably a function of the `nix` DSL's suitability in creating packages/derivations

After speaking to Jules I realised next is actually a language, next packages is a package repository created using the next language, and there is a package and the command line tool is used as a package manager. Nix SOS is a operating system built with the same principles
Nix is teaming Unix with functional programming bracket reference tweak blog post bracket. 
