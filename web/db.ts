import { path, hash, first } from './utilities'
import { User, Squigg } from './types'

const low = require('lowdb')

type UserDb = {
  username : string,
  hash : string,
  id: string
} | undefined

const db =
  low(path('../db.json'))

db.defaults({ squiggs: [], users: [] })
  .write()

const userPromise = (user : UserDb) : Promise<User> =>
  (user !== undefined)
    ? Promise.resolve({ id: user.id })
    : Promise.reject('Could not find user.')

export const findUser = (username : string, password: string) : Promise<User> => {
  const users : UserDb[] =
    db.get('users')
      .find({ username, hash: hash(password) })
      .value()
  return userPromise(first(users))
}

export const findUserWithId = (id : string) : Promise<User> => {
  const users : UserDb[] =
    db.get('users')
      .find({ id })
      .value()
  return userPromise(first(users))
}

export const getTopSquiggs = () : Promise<Squigg[]> => {
  const topSquiggs : Squigg[] =
    db.get('squiggs')
      .sortBy('votes.up')
      .take(5)
      .value()
  return topSquiggs ? Promise.resolve(topSquiggs) : Promise.reject('Could not get squiggs.')
}