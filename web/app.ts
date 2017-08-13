import * as express from 'express'
import * as morgan from 'morgan'
import * as bodyParser from 'body-parser'
import { views } from './routes'
import { path } from './utilities'
import { passport } from './auth'
import { port, secret, httpsEnabled } from './config'
const session = require('express-session')

const app = express()

app.use(morgan('tiny'))
app.use(bodyParser.json())
app.use(session({
  secret,
  resave: false,
  saveUninitialized: true,
  cookie: { secure: httpsEnabled }
}))
app.use(passport.initialize())
app.use(passport.session())
app.use(express.static(path('public')))
app.set('view engine', 'pug')
app.set('views', __dirname)

app.use(views.app)

app.listen(port, () => console.info(`Ready at http://localhost:${port}`))