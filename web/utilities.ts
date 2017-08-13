import * as pathNode from 'path'
import * as crypto from 'crypto'
import { secret } from './config'
const uuid = require('uuid/v1')

export const path = (filePath : string) : string =>
  pathNode.join(__dirname, filePath)

export const hash = (str : string) : string =>
  crypto
    .createHmac('sha256', secret)
    .update(str)
    .digest('hex')

export const first = <T>(list : T[] | undefined) : T | undefined =>
  (list && list.length > 0)
    ? list[0]
    : undefined

export const debug = <T>(thing : T) : T => {
  console.log(`DEBUG ${thing}`)
  return thing
}

export const getUniqueId = () : string =>
  uuid()