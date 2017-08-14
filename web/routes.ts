import { Request, Response } from 'express'
import { Squigg, User } from './types'
import { getTopSquiggs, createUser, createSquigg, findUser } from './db'

export const views = {
  app: (req : Request, res : Response) =>
    getLocals(req).then(locals => res.render('index', locals))
}

type Meta = {
  title : String,
  description : String
}

type Context = {
  user : User,
  squiggs : Squigg[]
}

type Locals = {
  meta : Meta,
  context : Context
}

const getLocals = (req : Request) : Promise<Locals> =>
  getTopSquiggs()
    .then((topSquiggs : Squigg[]) => ({
      meta: {
        title: 'baroot?',
        description: 'baroot, baroot.'
      },
      context: {
        user: req.user || null,
        squiggs: topSquiggs
      }
    }))

const handleSignIn = (req : Request, res : Response) =>
  findUser(req.body.username || '', req.body.password || '')
    .then(user => req.login(user, (error : any) =>
      error
        ? res.json({
          error: true,
          message: 'Could not sign in.',
          data: []
        })
        : res.json({
          error: false,
          message: 'Signed in successfully!',
          data: [ req.user ]
        })
    ))
    .catch(_reason =>
      res.json({
        error: true,
        message: 'Could not sign in.',
        data: []
      })
    )

export const api = {

  signUp (req : Request, res : Response) {
    createUser(req.body.username || '', req.body.password || '')
      .then((_user) => handleSignIn(req, res))
      .catch((reason) => {
        console.error(reason)
        res.json({
          error: true,
          message: typeof reason === 'string'
            ? reason
            : 'Could not create user.',
          data: []
        })
      })
  },

  signIn: handleSignIn,

  signOut: (req : Request, res : Response) =>
    Promise.resolve((req.user) ? req.logout() : undefined)
      .then(() => res.json({
        error: false,
        message: 'Signed out.',
        data: []
      })),

  squigg: (req: Request, res : Response) =>
    createSquigg(req.body.content, req.body.user)
      .then((squigg) => res.json({
        error: false,
        message: 'Squigg created!',
        data: [ squigg ]
      }))
      .catch(reason => res.json({
        error: true,
        message: typeof reason === 'string'
          ? reason
          : 'Could not create squigg.',
        data: []
      }))

}