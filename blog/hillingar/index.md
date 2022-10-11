---
pagetitle: "Hillingar | gibbr.org"
date: "2022-10-10 00:00:00"
bibliography: blog/hillingar/bibliography.bib
citation-style: blog/hillingar/ieee-with-url.csl
link-citations: true
---

# Hillingar: building Mirage unikernels with Nix

2022-10-10

> An arctic mirage[@lehnNovayaZemlyaEffect1979b]

![ ^[Generated with [Stable Diffusion](https://stability.ai/blog/stable-diffusion-public-release) and [GIMP](https://www.gimp.org/)] ](./hillingar2-caml.png){width=70% min-width=5cm}

As part of my master's thesis, I've been hosting an authoritative DNS server at `ns1.gibbr.org`.
More can be read in the dissertation^[['Spatial Name System' section 2.2 Internet Architecture](../../resources/mphil-diss.pdf#sec-internet-arch)], but DNS is one of the fundamental building blocks of the modern Internet.
And as part of my master's thesis procrastination, I've been running it on a NixOS machine.
Using NixOS, deploying a DNS server is as simple as:
```nix
{
  services.bind = {
    enable = true;
    zones."gibbr.org" = {
      master = true;
      file = "gibbr.org.zone";
    };
  };
}
```

Which we can then query with
```bash
$ dig gibbr.org @ns1.gibbr.org +short
45.77.205.198
```

Setting up a glue record with our registrar pointing `ns1.gibbr.org` to the IP address of our DNS-hosting machine allows anyone to use our authoritative server via their resolver.

As you might notice, however, this is running the venerable bind written in C.
As an alternative, using functional high-level type-safe programming languages to create network applications can greatly benefit safety and usability whilst maintaining performant execution[@madhavapeddyMelangeCreatingFunctional2007a].
One such language is OCaml.

The MirageOS project is a deployment method for these OCaml programs[@madhavapeddyUnikernelsLibraryOperating2013a].
Instead of running them as a traditional Unix process, we instead create a specialised 'unikernel' operating system to run the application, which allows dead code elimination improving security with smaller attack surfaces and improved efficiency.

However, to deploy a Mirage unikernel with NixOS one has to use the imperative deployment methodologies native to the OCaml ecosystem, eliminating the benefit of reproducible systems that Nix gives us.
This blog post will explore how we enabled reproducible deployments of Mirage unikernels with Nix.

## Nix

![ Nix snowflake^[As 'nix' means snow in Latin. Credits to Tim Cuthbertson.] ](./nix-snowflake.svg){width=60% min-width=5cm}

At this point, the curious reader might be wondering, what on earth is 'Nix'?

Nix is a deployment system that uses cryptographic hashes to compute unique paths for components (i.e. a dependency) which are stored in a read-only directory, the Nix store, at `/nix/store/<hash>-<name>`.
<!-- We replace references to a component with this absolute path, or symlink into the nix store for the system path, for example. -->
This provides a number of benefits including concurrent installation of multiple versions of a package, atomic upgrades and downgrades, and 
multiple user environments[@dolstraNixSafePolicyFree2004a].

Nix uses a declarative domain-specific language (DSL), also called 'Nix', to build and configure software.
The snippet used to deploy the DNS server is in fact a Nix expression.
This example doesn't demonstrate it but Nix is Turing complete, being inspired by Haskell. 
Nix does not, however, have a type system.

We used the DSL to write derivations for software, which describes how to build said software with input components and a build script.
This Nix expression is then 'instantiated' to create 'store derivations' (`.drv` files), which is the low-level representation of how to build a single component.
This store derivation is 'realised' into a built artefact, hereafter referred to as 'building'.

Possibly the simplest Nix derivation uses bash to create a single file containing `Hello, World!`:
```nix
{ pkgs ? import <nixpkgs> {  } }:

builtins.derivation {
  name = "hello";
  system = builtins.currentSystem;
  builder = "${nixpkgs.bash}/bin/bash";
  args = [ "-c" ''echo "Hello, World!" > $out'' ];
}
```
Note that `derivation` is a function that we're calling with one argument which is a set of attributes.

We can instantiate this Nix derivation expression to create a store derivation:
```
$ nix-instantiate default.nix
/nix/store/5d4il3h1q4cw08l6fnk4j04a19dsv71k-hello.drv
$ nix show-derivation /nix/store/5d4il3h1q4cw08l6fnk4j04a19dsv71k-hello.drv
{
  "/nix/store/5d4il3h1q4cw08l6fnk4j04a19dsv71k-hello.drv": {
    "outputs": {
      "out": {
        "path": "/nix/store/4v1dx6qaamakjy5jzii6lcmfiks57mhl-hello"
      }
    },
    "inputSrcs": [],
    "inputDrvs": {
      "/nix/store/mnyhjzyk43raa3f44pn77aif738prd2m-bash-5.1-p16.drv": [
        "out"
      ]
    },
    "system": "x86_64-linux",
    "builder": "/nix/store/2r9n7fz1rxq088j6mi5s7izxdria6d5f-bash-5.1-p16/bin/bash",
    "args": [ "-c", "echo \"Hello, World!\" > $out" ],
    "env": {
      "builder": "/nix/store/2r9n7fz1rxq088j6mi5s7izxdria6d5f-bash-5.1-p16/bin/bash",
      "name": "hello",
      "out": "/nix/store/4v1dx6qaamakjy5jzii6lcmfiks57mhl-hello",
      "system": "x86_64-linux"
    }
  }
}
```

And build the store derivation:
```sh
$ nix-store --realise /nix/store/5d4il3h1q4cw08l6fnk4j04a19dsv71k-hello.drv
/nix/store/4v1dx6qaamakjy5jzii6lcmfiks57mhl-hello
$ cat /nix/store/4v1dx6qaamakjy5jzii6lcmfiks57mhl-hello
Hello, World!
```

Most nix tooling does these two steps together:
```
nix-build default.nix
this derivation will be built:
  /nix/store/q5hg3vqby8a9c8pchhjal3la9n7g1m0z-hello.drv
building '/nix/store/q5hg3vqby8a9c8pchhjal3la9n7g1m0z-hello.drv'...
/nix/store/zyrki2hd49am36jwcyjh3xvxvn5j5wml-hello
```

Nix realisations (hereafter referred to as builds) are done in isolation to ensure reproducibility.
Projects often rely on interacting with package managers to make sure all dependencies are available, and may implicitly rely on system configuration at build time.
To prevent this, every Nix derivation is built in isolation, without network access or access to the global file system, with only other Nix derivations as inputs.

> The name Nix is derived from the Dutch word niks, meaning nothing; build actions do not see anything that has not been explicitly declared as an input[@dolstraNixSafePolicyFree2004a].

<!-- There are analogies to functional program versus imperative programming, but applied to system management and software builds/deployment. -->

#### Nixpkgs

You may have noticed a reference to `nixpkgs` in the above derivation.
As every input to a Nix derivation also has to be a Nix derivation, one can imagine the tedium involved in creating a Nix derivation for every dependency of your project.
However, Nixpkgs^[ [github.com/nixos/nixpkgs](https://github.com/nixos/nixpkgs) ] is a large repository of software packaged in Nix, where a package is a Nix derivation.
We can use packages from Nixpkgs as inputs to a Nix derivation, as we've done with `bash`.

There is also a command line package manager installing packages from Nixpkgs, which is why people often refer to Nix as a package manager.
While Nix, and Therefore nix package management, is primarily source-based -- since derivations describe how to build software from source -- binary deployment is an optimization of this.
Since packages are built in isolation and entirely determined by their inputs, binaries can be transparently deployed by downloading them from a remote server instead of building the derivation locally.

#### NixOS

NixOS^[[nixos.org](https://nixos.org)] is a Linux distribution built with Nix from a modular, purely functional specification[@dolstraNixOSPurelyFunctional2010].
It has no traditional filesystem hierarchy (FSH) -- like `/bin`, `/lib`, `/usr` -- but instead stores all components in `/nix/store`.
The configuration of the system is managed by Nix, with configuration files being built from modular Nix expressions.
NixOS modules are just that -- small bits of configuration written in Nix that can be composed to build a full NixOS system.
For example, the expression used to deploy a DNS server is a NixOS module.
The system is built from this configuration like a Nix derivation is built.

NixOS minimises global mutable state that -- without knowing it -- you might rely on being set up in a certain way.
For example, you might follow some instructions to run a series of shell commands and edit some files in a certain way to get a piece of software working, but then forgot and fail to document the process.
Nix forces you to encode this in a reproducible way, which is extremely useful for replicating software configurations and deployments, aiming to solve the 'It works on my machine' problem.
Docker is often used to fix this configuration problem, but nix aims to be more reproducible (restricting network access).
This can be frustrating at times because it can make it harder to get off the ground with a project, but I've found the benefits outway the cons for me.

My own NixOS configuration is publicly available^[ [github.com/RyanGibb/nixos](https://github.com/RyanGibb/nixos) ].
This makes it trivial to reproduce my system -- a collection of various configurations, services, and hacks -- on another machine.
I use it to manage servers, workstations, and more.
Compared to my previous approach of maintaining a git repository of dotfiles, this is much more modular, reproducible, and flexible.
And if you want to deploy some new piece of software or service, it can be as easy as changing a single line in your system configuration.

Despite these advantages, the reason I switched to NixOS from Arch Linux was simpler; NixOS allows rollbacks.
As Arch packages bleeding-edge software with rolling updates it would frequently happen that some new version of something I was using would break due to a bug.
Arch has one global coherent package set, like Nixpkgs, except you can use multiple instances of Nixpkgs (i.e. channels) at once as the Nix store allows multiple versions of a dependency to be stored at once, whereas Arch just doesn't support partial upgrades.
So the options were to wait for the bug to be fixed, or manually rollback all the updated packages by inspecting the pacman (the Arch package manager) log and reinstalling the old versions from the local cache.
While there may be tools on top of pacman to improve this, the straw that broke the caml's back was when I was updating the Linux kernel, something went wrong, and the machine crashed.
I had to reinstall the kernel from a live USB to fix the issue, which is not something you want to have to do to your main workstation when you may have pressuring concerns like an upcoming deadline.
Nix's atomic upgrades mean this wouldn't have been an issue in the first place.
And every new system configuration creates a GRUB entry, so you can boot previous systems from your UEFI/BIOS.

The blog post 'Nix – taming Unix with functional programming' by Valentin Gagarin at Tweag^[[tweag.io/blog/2022-07-14-taming-unix-with-nix](https://www.tweag.io/blog/2022-07-14-taming-unix-with-nix/)] gives an interesting summary of Nix and NixOS.

To summarise the parts of the Nix ecosystem that we've discussed:

![](./nix-stack.svg){width=50% min-width=5cm}

#### Flakes

We also use Nix flakes for this project.
Without going into too much depth, for our purposes, they enable hermetic evaluation of nix expressions and provide a standard way to compose Nix projects.
<!-- One of the reasons for improving Nix project composing is that there's some discussion around the sustainability of the Nixpkgs monorepo workflow^[https://discourse.nixos.org/t/nixpkgss-current-development-workflow-is-not-sustainable/18741](https://discourse.nixos.org/t/nixpkgss-current-development-workflow-is-not-sustainable/18741]. -->
Integrated with flakes there is also a new `nix` command aimed at improving the UI of Nix.
More detail about flakes can be read in a series of blog posts by Eelco on the topic^[[tweag.io/blog/2020-05-25-flakes](https://www.tweag.io/blog/2020-05-25-flakes/)].

## MirageOS

![ ^[Credits to Takayuki Imada] ](./mirage-logo.svg){width=50% min-width=5cm}

As mentioned, MirageOS is a library operating system that creates unikernels that contains low-level operating system code and high-level application code bundled into one kernel and one address space.
<!-- security, performance, speed -->
It was the first such 'unikernel creation framework', but it comes from a long lineage of OS research such as the exokernel library OS architecture.
You can remove a bunch of dead codes because there's no interface between the application and the open on the operating system.
Mirage unikernels are written in the typesafe high-level functional programming language OCaml.
OCaml is a functional programming language, but it's a bit more practical than others (like Haskell) supporting imperative programming too.

![ Contrasting software layers in existing VM appliances vs. unikernel's standalone kernel compilation approach[@madhavapeddyUnikernelsLibraryOperating2013a] ](./mirage-diagram.svg){width=50% min-width=5cm}

Mirage was created to run on hypervisors in the cloud, but there is ongoing work towards porting it to run on bare metal for IoT applications.
<!-- But hw support tricky. -->

## Deploying Mirage unikernels


Why couldn't we just write a NixOS module to deploy a unikernel?
Well, first we need to support building unikernels with Nix.
This blog post will explore how to do that to provide easy deployability of Mirage unikernels.


- nixOS modules
- …requires packaging with nix
- …requires building with nix
- nixpkgs has one global set of package versions
- but nix doesn’t deal with more complicated dependency versioning




3 types:
- ‘system’ (e.g. gmp)
- ‘libraries’ (e.g. fmt)
- ‘project’ (e.g. lib/something.ml)

Nix deals well with system dependencies, but not library dependencies
Opam deals well with library dependencies, but not system dependencies
Dune deals well with project libraries, but not the others (although this may be changing)



could do version solving in nix




The build script in a Nix derivation, if it doesn't invoke a compiler directly, often invokes a build system like `make`.
But Nix can also be considered a build system too[@mokhovBuildSystemsCarte2018].
It takes a build graph and computes.

If any of the detivtion's inputs change, the hash will change, and the path will change. So this.captures deep traces of inputs (as each input is also a deticaiton with a hash base on its inputs).

Nix can also be thought as a coarse grained build system 

and low level stuff?
[1]	E. Dolstra, The purely functional software deployment model. S.l.: s.n., 2006.
chapter 10






- due to nix not dealing with well with multiple versions, we need opam’s solver
- github.com/tweag/opam-nix creates nix derivations for OCaml projects using it
- We added opam monorepo support for tweag/opam-nix (merged yesterday!)
- and created a nix flake for building nix projects: github.com/RyanGibb/hillingar



NixOS modules
<!-- https://github.com/NixOS/nixpkgs/blob/fe76645aaf2fac3baaa2813fd0089930689c53b5/nixos/modules/services/networking/bind.nix -->

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
(
Opam2nix
Depends on binary of itself at build time: not very Nixy
Not as minimal - (LOC stats) probably a function of the `nix` DSL's suitability in creating packages/derivations
)

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


limitations:
- dune cache use for monorepo deps
    - as we invoke dune inside a nix derivation
- Source deduplication takes the higher version of the dev-repo
    - https://github.com/tarides/opam-monorepo/issues/331




what are the benefits?:
- enables unikernel deployments with nixOS modules
- reproducible builds with system dependencies (depexts in opam parlance)
    - as well as allow composing multiple language environments
- we can benefit from nix cross compilation support (?)



## Conclusion

Nix and Mirage
both brining some kind of functional paradigm to OSes
but top down vs bottom up



Future work:
- use opam monorepo’s solver
- binary caching of opam package derivations
- incorporate into CI for reproducible builds
- nixOS module deployments!


- github.com/RyanGibb/hillingar
- system config is nice
	- NixOS module


reflections:
- the nix DSL’s lack of typing is a pain when writing complicated code
    - github.com/tweag/nickel could prove interesting
- there are many obscure problems that arise when playing dependencies like this
    - more so than other kinds programming
    - but hopefully if we encode them with nix so others won’t have them!
- mirage and nix are of a similar theme
    - bringing functional paradigm to operating systems
    - bottom up vs top down



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




Try it out!

```
With your unikernel…

$ nix flake new . -t github:/RyanGibb/hillingar
$ sed -i 's/throw "Put the unikernel name here"/"<unikernel-name>"/g' flake.nix
$ nix build .#<target>

Please open an issue (or message the #nix slack channel) if you encounter any issues.




##### Thanks To

- Lucas for OCaml ecosystem
- Balsoft for getting me to speed with the `opam-nix` project and working with me on the opam monorepo workflow integration
- Anil for proposing the project
- bjorg for icelandic language consulting


This worked was completed as part of an internship with Tarides. A copy of this blog post can be found on Tarides website.

---

If you spot any errors, or have any questions, please get in touch at [ryan@gibbr.org](mailto:ryan@gibbr.org).

---

#### References

<div id="refs"></div>


<div id="footnotes"></div>
