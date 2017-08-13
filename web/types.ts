export type User = {
  id: String
}

export type Squigg = {
  content : String,
  user : User,
  votes: {
    up : Number
  }
}