---
pagetitle: "Nim | gibbr.org"
date: "2021-07-26 00:00:00"
---

# Nim

I recently attended a talk by Simon Peyton Jones titled "Immutability changes everything: 40 years of functional programming" which roughly chronologed Simon's research career.
In this talk Simon described how he originally became interested in Computer Science through two problems: the Angry Bank Customer and Nim.

## Angry Bank Customer

Consider the scenario: you're a overworked bank teller who, every week, has the same angry customer.
This customer demands to withdraw a varying amount of money each week, and becomes irate if you cannot hand them their desired amount immediately.
How, aside from more diplomatic means, can you satisfy this customer?

You decide to prepare piles of cash such that you can make up his desired amount by grabbing a combination.
Starting with a £1 pile and a £2 pile, you can make up to £3.
So you add a pile of £4.
Which this you can make any number up to £7 (e.g. 5=4+1, 6=4+2, 7=4+3), so you add a £8 pile, a £16 pile, a £32 pile.
Before you know it, you've reinvented the binary numeral system.

While this is a relatively straightforward example, the second problem poses a more challenging statement also relying on base-2.

## Nim




## S6 AH Computing Project

I went to school in Scotland, where as part of Senior Phase 6 Advanced Higher Computing Project


The reason why my ears perked up at the mention of Nim was because this was the game I chose to implement for my Advanced Higher Computing Project.




But you only have 

S6 AH Computing Proiject

Nim - Honestly don't remember where I found this game, but I thought it was interesting.

And once you know the trick, building a perfect AI opponent is trivial.

Haven't thought about this in years, apart from adding a repo and trying and failure to compile it (an interesting exercise in reproducibility)

Inane requirements - like writing out the entire program in pseuocode beforehand and using a strict waterful methodology


I had been taught Vb, had friend's learning Python & JAva, but I really only knew how to code in the Visual Studio IDE.
I had enough foresight to want to move away from Visual Basic, and C# was a natural choice due to IDE support and feature parity (same IR) https://en.wikipedia.org/wiki/Comparison_of_C_Sharp_and_Visual_Basic_.NET

This started my prefered way of learning programming languages: just start building something and figure things out from there.
Normally this means getting stuck and consulting stack overflow or preferable the documentation.
I view programming as kind of like riding a bike - it's all well and good to read a textbook on how to do it but to do it in reality you need to practive






needless to say some of these were completed


```
private void AITurn() {
    int nim_sum = 0x0;
    int[] Stacks_binary_values = new int[number_of_stacks];
    for (int i = 0; i < number_of_stacks; i++) {
        Stacks_binary_values[i] = Convert.ToByte(Stacks[i].Text);
        nim_sum = nim_sum ^ Stacks_binary_values[i];stacks binary values
    }
    if (nim_sum == 0x0 || random.NextDouble() > AIdifficulty) {
        int stack_index = random.Next(number_of_stacks);
        Stacks[stack_index].Text = random.Next(int.Parse(Stacks[stack_index].Text)-1).ToString();
        if (Stacks[stack_index].Text == "0") {
            Stacks[stack_index].Hide();
            Disks[stack_index].Hide();
        }
        current_stack = stack_index + 1;
    } else {
        for (int i = 0; i < number_of_stacks; i++) {
            if ((nim_sum ^ Stacks_binary_values[i]) < Stacks_binary_values[i]) {
                Stacks_binary_values[i] = nim_sum ^ Stacks_binary_values[i];
                Stacks[i].Text = Convert.ToString(Stacks_binary_values[i]);
                if (Stacks[i].Text == "0") {
                    Stacks[i].Hide();
                    Disks[i].Hide();
                }
                current_stack = i + 1;
                break;
            }
        }
    }
    TurnTaken();
}
```

## Computing Education


Now what's the point of this article? What do you want people to take away?








