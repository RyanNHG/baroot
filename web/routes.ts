import { Request, Response } from 'express'
import { Squigg, User } from './types'
import { getTopSquiggs } from './db'

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