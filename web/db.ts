import { path, hash, getUniqueId } from './utilities'
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

const usernameTaken = (username : string) : boolean =>
  db.get('users')
    .find({ username })
    .value() != null

export const findUser = (username : string, password: string) : Promise<User> => {
  const user : UserDb =
    db.get('users')
      .find({ username, hash: hash(password) })
      .value()
  return userPromise(user)
}

export const findUserWithId = (id : string) : Promise<User> => {
  const user : UserDb =
    db.get('users')
      .find({ id })
      .value()
  return userPromise(user)
}

export const createUser = (username : string, password : string) : Promise<User> => {
  if (!username || !password) {
    return Promise.reject('Must provide a username and password.')
  } else if (usernameTaken(username)) {
    return Promise.reject('Username is already taken.')
  } else {
    const newUser = {
      id: getUniqueId(),
      username: username,
      hash: hash(password)
    }

    db.get('users')
      .push(newUser)
      .write()

    return Promise.resolve({
      id: newUser.id
    })
  }
}

export const getTopSquiggs = () : Promise<Squigg[]> => {
  const topSquiggs : Squigg[] =
    db.get('squiggs')
      .sortBy('votes.up')
      .take(5)
      .value()
  return topSquiggs ? Promise.resolve(topSquiggs) : Promise.reject('Could not get squiggs.')
}