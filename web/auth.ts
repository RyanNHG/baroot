import * as passport_ from 'passport'
import { findUser, findUserWithId } from './db'
import { User } from './types'
const { Strategy } = require('passport-local')

export const passport = passport_

passport.use(new Strategy((username : string, password : string, done : Function) =>
  findUser(username, password)
    .then(user => done(null, user))
    .catch(reason => done(null, false, reason))
))

passport.serializeUser((user : User, done : Function) =>
    done(null, user.id)
)

passport.deserializeUser((id : string, done : Function) =>
  findUserWithId(id)
    .then(user => done(null, user))
    .catch(reason => done(reason, false))
)