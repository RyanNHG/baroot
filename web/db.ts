import { path, hash, getUniqueId, prettify } from './utilities'
import { User, Squigg } from './types'

const low = require('lowdb')

type Id = string
type UserId = Id
type SquiggId = Id

type UserDb = {
  username : string,
  hash : string,
  id: UserId
} | undefined

type SquiggDb = {
  content : string,
  user : UserId,
  timestamp: Date,
  votes: UserId[],
  flags: UserId[],
  id: SquiggId
}

const db =
  low(path('../db.json'))

db.defaults({ squiggs: [], users: [] })
  .write()

const userPromise = (user : UserDb) : Promise<User> =>
  (user !== undefined)
    ? Promise.resolve({ id: user.id })
    : Promise.reject('Could not find user.')

const toSquigg = (squigg : SquiggDb) : Squigg => ({
  id: squigg.id,
  content: squigg.content,
  timestamp: prettify(new Date(squigg.timestamp)),
  user: squigg.user,
  votes: squigg.votes
})

const squiggPromise = (squigg : SquiggDb) : Promise<Squigg> =>
  (squigg !== undefined)
    ? Promise.resolve(toSquigg(squigg))
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
  const topSquiggs : SquiggDb[] =
    db.get('squiggs')
      .sortBy('votes')
      .take(5)
      .value()
  return topSquiggs
    ? Promise.resolve(topSquiggs.map(toSquigg))
    : Promise.reject('Could not get squiggs.')
}

export const createSquigg = (content : string, user : string) : Promise<Squigg> => {
  if (content && user) {
    const newSquigg : SquiggDb = {
      id: getUniqueId(),
      content,
      user,
      timestamp: new Date(Date.now()),
      votes: [ user ],
      flags: []
    }

    db.get('squiggs')
      .push(newSquigg)
      .write()

    return squiggPromise(newSquigg)
  } else {
    return Promise.reject('Need content and a user id.')
  }
}