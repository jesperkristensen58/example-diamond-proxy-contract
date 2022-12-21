/* ==========================================================================================

Create simple Diamond contract as an NFT with possibility to buy the NFT with ERC20 Tokens.

Tests the diamond and facets.

@author: Jesper Kristensen
============================================================================================= */

const { expect } = require('chai')

// HELPER: get function selectors from a contract
function getSelectors (contract) {
  // get the function signatures from the ABI of the contract:
  const signatures = Object.keys(contract.interface.functions)
  // convert from signature to selector:
  const selectors = signatures.reduce((acc, val) => {
    acc.push(contract.interface.getSighash(val))
    return acc
  }, [])
  return selectors
}

describe('Create a Simple Diamond Contract', async function () {
  let diamond
  let tx
  let receipt
  let alice
  let bob

  /* Before each test - run this setup */
  before(async function () {

    [contractOwner, alice, bob] = await ethers.getSigners();

    // deploy simple Diamond
    const Diamond = await ethers.getContractFactory('Diamond')
    diamond = await Diamond.deploy(contractOwner.address)
    await diamond.deployed()

    console.log('Diamond deployed:', diamond.address)
  })

  /*================================================================*/
  /***************               NFT FACET               ************/
  /*================================================================*/

  it('should add the NFT facet', async () => {
    // we need to link the NFTFacet to its Library function first:
    const NFTLib = await ethers.getContractFactory('LibNFT')
    const nftlib = await NFTLib.deploy()
    await nftlib.deployed()

    const NFTFacet = await ethers.getContractFactory('NFTFacet', {
      libraries: {
        LibNFT: nftlib.address,
      }}
    )
    const nftFacet = await NFTFacet.deploy()
    await nftFacet.deployed()
    // now we have the NFT Facet deployed with its library dependency

    // get all the function selectors covered by this facet - we need that during the cut below:
    const selectors = getSelectors(nftFacet)

    // now make the diamond cut (register the facet) - cut the NFT Facet onto the diamond:
    tx = await diamond.diamondCut(
      {
        facetAddress: nftFacet.address, // the nft facet is deployed here
        functionSelectors: selectors // these are the selectors of this facet (the functions that are supported)
      }, { gasLimit: 800000 }
    )
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
  })

  // Now test general behavior and expect that the NFT and ERC20 features work
  it('should mint the nft as expected and be able to transfer it', async () => {
    const nftFacet = await ethers.getContractAt('NFTFacet', diamond.address)

    await expect(nftFacet.ownerOf(0)).to.be.revertedWith("ERC721: invalid token ID")
    await expect(nftFacet.ownerOf(1)).to.be.revertedWith("ERC721: invalid token ID")
    expect(await nftFacet.balanceOf(alice.address)).to.equal(0)

    tx = await nftFacet.mint(alice.address, 1)
    await tx.wait()

    // confirm that alice got the NFT
    expect(await nftFacet.balanceOf(alice.address)).to.equal(1)
    await expect(nftFacet.ownerOf(0)).to.be.revertedWith("ERC721: invalid token ID")
    expect(await nftFacet.ownerOf(1)).to.equal(alice.address)

    tx = await nftFacet.connect(alice).transfer(bob.address, 1)
    await tx.wait()

    expect(await nftFacet.balanceOf(alice.address)).to.equal(0)
    expect(await nftFacet.balanceOf(bob.address)).to.equal(1)

    // bob burns it
    tx = await nftFacet.connect(bob).burn(1)
    await tx.wait()

    // it's gone:
    expect(await nftFacet.balanceOf(alice.address)).to.equal(0)
    expect(await nftFacet.balanceOf(bob.address)).to.equal(0)

    // mint more
    tx = await nftFacet.mint(alice.address, 0)
    await tx.wait()
    tx = await nftFacet.mint(bob.address, 1)
    await tx.wait()
    tx = await nftFacet.mint(bob.address, 2)
    await tx.wait()

    // make sure balances and ownership are correct
    expect(await nftFacet.balanceOf(alice.address)).to.equal(1)
    expect(await nftFacet.balanceOf(bob.address)).to.equal(2)
    
    expect(await nftFacet.ownerOf(0)).to.equal(alice.address)
    expect(await nftFacet.ownerOf(1)).to.equal(bob.address)
    expect(await nftFacet.ownerOf(2)).to.equal(bob.address)
  })

  /*================================================================*/
  /***************             ERC20 FACET               ************/
  /*================================================================*/

  it('should add the ERC20 facet', async () => {
    // we need to link the ERC20Facet to its Library function first:
    // const ERC20lib = await ethers.getContractFactory('LibERC20')
    // const erc20lib = await ERC20lib.deploy()
    // await erc20lib.deployed()

    const ERC20Facet = await ethers.getContractFactory('ERC20Facet')
    const erc20Facet = await ERC20Facet.deploy()
    await erc20Facet.deployed()
    // now we have the NFT Facet deployed with its library dependency

    // get all the function selectors covered by this facet - we need that during the cut below:
    const selectors = getSelectors(erc20Facet)

    // now make the diamond cut (register the facet) - cut the ERC20 Facet onto the diamond:
    tx = await diamond.diamondCut(
      {
        facetAddress: erc20Facet.address, // the nft facet is deployed here
        functionSelectors: selectors // these are the selectors of this facet (the functions that are supported)
      }, { gasLimit: 800000 }
    )
    receipt = await tx.wait()
    if (!receipt.status) {
      throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
  })

  it('should add ERC20 Token functionality: to buy the NFT with the token', async () => {

    // note how the facets are sitting at the same address (aka part of the same diamond)
    const nftFacet = await ethers.getContractAt('NFTFacet', diamond.address)
    const erc20Facet = await ethers.getContractAt('ERC20Facet', diamond.address)

    tx = await erc20Facet.erc20mint(alice.address, 20)
    await tx.wait()

    expect(await erc20Facet.erc20balanceOf(alice.address)).to.equal(20)
    expect(await erc20Facet.erc20balanceOf(bob.address)).to.equal(0)

    tx = await erc20Facet.connect(alice).erc20transfer(bob.address, 10)
    await tx.wait()

    expect(await erc20Facet.erc20balanceOf(alice.address)).to.equal(10)
    expect(await erc20Facet.erc20balanceOf(bob.address)).to.equal(10)

    tx = await erc20Facet.connect(alice).erc20transfer(bob.address, 10)
    await tx.wait()

    expect(await erc20Facet.erc20balanceOf(alice.address)).to.equal(0)
    expect(await erc20Facet.erc20balanceOf(bob.address)).to.equal(20)
    expect(await erc20Facet.erc20balanceOf(nftFacet.address)).to.equal(0)

    // alice does not have any tokens, and can therefor not transfer anything
    await expect(erc20Facet.connect(alice).erc20transfer(bob.address, 20)).to.be.revertedWith("ERC20: transfer amount exceeds balance");

    // alice cannot transfer bob's tokens (w/o approval - and none has been given)
    await expect(erc20Facet.connect(alice).erc20transferFrom(bob.address, alice.address, 20)).to.be.revertedWith("ERC20: insufficient allowance");

    // bob now gives alice approval:
    tx = await erc20Facet.connect(bob).erc20approve(alice.address, 20)
    await tx.wait()

    expect(await erc20Facet.erc20balanceOf(alice.address)).to.equal(0)
    expect(await erc20Facet.erc20balanceOf(bob.address)).to.equal(20)
    expect(await erc20Facet.erc20balanceOf(nftFacet.address)).to.equal(0)

    // now alice can transfer from bob to herself
    tx = await erc20Facet.connect(bob).erc20approve(alice.address, 20)
    await tx.wait()

    tx = await erc20Facet.connect(alice).erc20transferFrom(bob.address, alice.address, 20)
    await tx.wait()

    expect(await erc20Facet.erc20balanceOf(alice.address)).to.equal(20)
    expect(await erc20Facet.erc20balanceOf(bob.address)).to.equal(0)
    expect(await erc20Facet.erc20balanceOf(nftFacet.address)).to.equal(0)

    // let's transfer back to bob
    tx = await erc20Facet.connect(alice).erc20transfer(bob.address, 20)
    await tx.wait()

    expect(await erc20Facet.erc20balanceOf(alice.address)).to.equal(0)
    expect(await erc20Facet.erc20balanceOf(bob.address)).to.equal(20)
    expect(await erc20Facet.erc20balanceOf(nftFacet.address)).to.equal(0)

    // next, use the 20 tokens to mint an NFT
    expect(await nftFacet.balanceOf(bob.address)).to.equal(2) // from previous test calls
    await expect(nftFacet.ownerOf(4)).to.be.revertedWith("ERC721: invalid token ID") // nobody owns id 4 yet

    tx = await nftFacet.connect(bob).mintWithERC20(4) // mint ID 4 (not minted yet)
    await tx.wait()

    expect(await nftFacet.balanceOf(bob.address)).to.equal(3) // bob owns one more
    expect(await nftFacet.ownerOf(4)).to.equal(bob.address) // and specifically owns id 4 just minted

    // he had to pay 20 tokens for it:
    expect(await erc20Facet.erc20balanceOf(alice.address)).to.equal(0)
    expect(await erc20Facet.erc20balanceOf(bob.address)).to.equal(0)
    expect(await erc20Facet.erc20balanceOf(nftFacet.address)).to.equal(20) // the nft facet got the funds    

    // now try alice
    tx = await erc20Facet.erc20mint(alice.address, 10) // mint less than needed
    await tx.wait()
    expect(await erc20Facet.erc20balanceOf(alice.address)).to.equal(10)

    await expect(nftFacet.connect(alice).mintWithERC20(6)).to.be.revertedWith("ERC20: transfer amount exceeds balance") // mint ID 6 (not minted yet)
    
    // give her some more tokens
    tx = await erc20Facet.erc20mint(alice.address, 100) // mint less than needed
    await tx.wait()
    expect(await erc20Facet.erc20balanceOf(alice.address)).to.equal(110)

    await expect(nftFacet.ownerOf(6)).to.be.revertedWith("ERC721: invalid token ID") // nobody owns id 6 yet

    tx = await nftFacet.connect(alice).mintWithERC20(6) // mint ID 4 (not minted yet)
    await tx.wait()

    expect(await nftFacet.ownerOf(6)).to.equal(alice.address)

    expect(await erc20Facet.erc20balanceOf(bob.address)).to.equal(0)
    expect(await erc20Facet.erc20balanceOf(alice.address)).to.equal(90)
    expect(await erc20Facet.erc20balanceOf(nftFacet.address)).to.equal(40)
  })
})
