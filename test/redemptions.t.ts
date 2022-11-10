import { expect } from 'chai'
import { ethers } from 'hardhat'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'

import { Redemptions, DAOMock } from '../typechain'

describe('Redemptions', () => {
    before(async () => {})

    beforeEach(async () => {})

    describe('initialize', () => {
        beforeEach(async () => {})
        it('reverts when passed non-contract address as redemption token', async () => {})
        it('reverts when passed non-contract address as redeemable token', async () => {})
        it('reverts when a redeemable token is duplicated', async () => {})
        it('can accept multiple redeemable tokens', async () => {})
    })

    describe('addRedeemableToken', () => {
        beforeEach(async () => {})
        it('should add an address to the redeemable tokens list', async () => {})
        it('reverts when adding more than max allowed redeemable tokens ', async () => {})
        it('reverts when adding already added token', async () => {})
        it('reverts when adding non-contract address', async () => {})
    })

    describe('removeRedeemableToken', () => {
        beforeEach(async () => {})
        it('Should remove token address', async () => {})
        it('reverts if removing token not present', async () => {})
    })

    describe('redeem(uint256 _amount)', () => {
        beforeEach(async () => {})
        it('Should redeem tokens as expected', async () => {})
        it('should allow redeeming up to max redeemable tokens and no more', async () => {})
        it('reverts if there is no eligible assets in the vault', async () => {})
        it('reverts if amount to redeem is zero', async () => {})
        it("reverts if amount to redeem exceeds account's balance", async () => {})
        it('reverts if all redeemable token amounts are zero', async () => {})
    })
})
