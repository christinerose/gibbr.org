---
pagetitle: "Augmented Reality Terminal | gibbr.org"
---

# Augmented Reality Terminal

2022-01-23

This blog post is about my project at Hack Cambridge Atlas 2022. See the associated devpost [here](https://devpost.com/software/augmented-reality-terminal).

NB: I was quite sleep-deprived while writing this so excuse any clunking wording.

<hr>

AR and VR headsets today are more akin to gaming consoles than to desktops and latops.

They are general purpose computers in that they can be programmed to do arbitrary tasks, but a hallmark of a flexible personal computer over which you have control is being able to develop new software on it, not just running software someone else has written.

Take phones as an example, while we all carry around more computing power than it took NASA to reach the moon in our pocket we instead are all hacking on laptops (or desktops - respect) in this competition. Arguably this is due to the interface of the device (i.e. small screen), and it is possible to get a Linux environment like Termux on an Android device, but the principle stands.

AR and VR headsets aren't limited by this interface constraint. Arguably, they could provide a better interface with infinite virtual monitors!

Dedicated [Virtual Reality Computers](https://simulavr.com/blog/kickstarter-pricing/) are possible, but their cost is rough 10x their mass-market peers. We could instead leverage existing hardware to support our vision. The minimum requirement of being able to develop software, and something that you can do a heck of a lot of on its own, is a terminal interface.

The justification for using the AR with the Hololens 2 is that it doesn't separate you from the real world, harking back to Mark Weiser's ideas of 'embodied virtuality rather than 'virtual reality'. VR headsets like the Oculus Quest 2 do have passthrough, but it's really janky.

Now being a Microsoft product the Hololens 2 runs Windows 10. I've been primarily using Linux machines for a while, and only using Linux machines or a *nix environment for development for longer than that. So this product involved majestically fighting with weird Microsoft C linker issues to build the [windows terminal](https://github.com/microsoft/terminal). I got some responses from some very helpful and very experienced people in the realm of the Windows Terminal and Hololens, but I gave up after about 12 hours of this, and instead fell to my backup plan: using a [SRCF](https://www.srcf.net/) shell in a box through the Hololense browser.

However, I did find a [nice blog post series](https://devblogs.microsoft.com/commandline/windows-command-line-backgrounder/) in the Windows Terminal (one of the few features of the Windows OS which I quite like).

Maybe it's just an issue with my lack of understanding, but the fact that these machines are so hard to hack on is an indicator that they are hostile to development. The user doesn't really own their own machine. This is important for technology education - how are kids meant to learn anything if they can't explore their own technology. Hopefully, this will change as AR moves from industrial markets to consumer markets (see Apple's upcoming AR glasses).

<iframe width="560" height="315" src="https://www.youtube.com/embed/cHmYd3KMBcM" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
