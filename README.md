# A Simple Example of a Diamond Contract

## The Background

The purpose of this repo is to show a simple example of a diamond contract. NOTE that this is for educational purposes only and is not intended to be used in production. Specifically, this implementation does not implement the required Loupe facet which is used to introspect facets. This is done because the repo represents a very minimal example trying to highlight the core elements before adding other facets on top.

See this repo for a more fleshed out template which adheres to all aspects of the Diamond EIP2535:
https://github.com/mudgen/diamond

Note in particular these repos: https://github.com/mudgen/diamond#diamond-repositories

## How to Run it

This repo provides a simple example of a diamond contract implementation and shows how it's deployed and tested from end to end.

To run it, simply type:

```shell
> npx hardhat test

Compiling 6 files with 0.8.9
Compilation finished successfully


  Create a Simple Diamond Contract
Diamond deployed: 0x5FbDB2315678afecb367f032d93F642f64180aa3
    ✓ should add the NFT facet (78ms)
    ✓ should mint the nft as expected and be able to transfer it (110ms)
    ✓ should add the ERC20 facet
    ✓ should add ERC20 Token functionality: to buy the NFT with the token (146ms)


  4 passing (743ms)
```

That's it.

Then, to learn more, go look at `./test/createDiamond.js` which shows you fully how the diamond contract is deployed, how facets are added and how to run the various facet functions and test the entire contract.

## Storage

Let's talk about storage and where the state is stored. In this simple example, all state is shared and stored in the `libDiamond` library. The facets and their respective facet libraries (like `libERC20`) does not store state in this example. They could certainly have, but that's a different project design.

So both facets have access to the same storage space stored in the diamond library. Each facet, as is necessary in a diamond contract, does not store state of course.

To extend this code to allow the separate facets to have their own storage spaces is easy: just define the structs in the facet libraries and read/write to those instead of the global space. In this sense, the current code is in a "hybrid" state I suppose.

## Contact
[![Twitter URL](https://img.shields.io/twitter/url/https/twitter.com/cryptojesperk.svg?style=social&label=Follow%20%40cryptojesperk)](https://twitter.com/cryptojesperk)


## License
This project uses the following license: [MIT](https://github.com/bisguzar/twitter-scraper/blob/master/LICENSE).
