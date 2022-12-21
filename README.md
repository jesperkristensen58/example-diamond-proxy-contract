# A Simple Example of a Diamond Contract

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

## Contact
[![Twitter URL](https://img.shields.io/twitter/url/https/twitter.com/cryptojesperk.svg?style=social&label=Follow%20%40cryptojesperk)](https://twitter.com/cryptojesperk)


## License
This project uses the following license: [MIT](https://github.com/bisguzar/twitter-scraper/blob/master/LICENSE).