# A Simple Example of a Diamond Contract

This repo provides a simple example of a diamond contract implementation and shows how it's deployed and tested from end to end.

To run it, simply type:

```shell
> npx hardhat test


  Create Diamond Contract
DiamondCutFacet deployed: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Diamond deployed: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
    ✓ should add the NFT facet (61ms)
    ✓ should add the ERC20 facet
    ✓ should mint the nft as expected and be able to transfer it (102ms)
    ✓ should add ERC20 Token functionality: to buy the NFT with the token (147ms)


  4 passing (862ms)
```

That's it.

Then, to learn more, go look at `./test/createDiamond.js` which shows you fully how the diamond contract is deployed, how facets are added and how to run the various facet functions and test the entire contract.

## Contact
[![Twitter URL](https://img.shields.io/twitter/url/https/twitter.com/cryptojesperk.svg?style=social&label=Follow%20%40cryptojesperk)](https://twitter.com/cryptojesperk)


## License
This project uses the following license: [MIT](https://github.com/bisguzar/twitter-scraper/blob/master/LICENSE).