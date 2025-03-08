# Appia

## To-do

- [ ] Figure shit out
- [ ] Handshake
- [ ] Search
- [ ] Message persistance
- [x] Name server
  - [x] Client
- [ ] Manage namesters screen
- [ ] Stop/start listening button

## design-doc

### Style guide

- Don't ever use the short form `ctx`.
- Trailaing commas wherever you can.
- Import ordering:

    <std imports>

    <package imports>

    <relative imports>

### Features

- [ ] Text chat

### Ideas

- Use HTTP name server for discovery/registration
- Use websockets

### Maybes

- NAT Traversal
- Use RSA public keys as Ids
- Allow any peer to be a name server

### Schema

    User {
      id: String // random string that's prefixed with `aid:`
      username: String
    }
    
    // This is the message class we'll be using but in code, there's
    // some hierarchy above it to allow extension. Some weird fields thus.
    TextMessage {
      id: int64 // incrementing ints
      type = "message" // if we ever need anymore
      timestamp: DateTime
      authorId: String
      authorUsername: String // denormalization should help with some pains
      forwadedFromId: Option<String> // forwarded only if not null
      forwardedFromUsername: Option<forwardedFromUsername>
      text: String
    }

    Room {
      users: List<User>
      entries: List<TextMessage>
    }

## dev-log

### NAT Translation

Is it out of scope? 

Yeah, it is. It most definitely is.
