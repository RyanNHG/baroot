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

const daysOfTheWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'November', 'December']

export const prettify = (date: Date) : string => {
  const day = daysOfTheWeek[date.getDay()]
  const month = months[date.getMonth()]
  const dayOfMonth = date.getDate()
  const year = date.getFullYear()
  const _militaryHour = date.getHours()
  const hour =
    (_militaryHour > 12) ? _militaryHour - 12 :
    (_militaryHour === 0) ? 12 :
    _militaryHour
  const minutes = date.getMinutes()
  const amPm = _militaryHour > 11 ? 'pm' : 'am'
  
  return `${day}, ${month} ${dayOfMonth}, ${year} ${hour}:${minutes} ${amPm}`
}