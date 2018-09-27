import { expect } from 'chai'
import asyncReturnErr from './asyncReturnErr'

export default async (asyncFn) => {
  const err = await asyncReturnErr(asyncFn)
  expect(
    typeof err !== 'undefined',
    'expected function to revert, but it succeeded'
  ).to.equal(true)
}
