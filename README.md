[Project Link](https://mutugiii.github.io/crowdfund_dApp/)

## About
This is a dApp that allows users to crowdfund for their various projects

## Features
- Users can create(list) a project to be crowdfunded
- Users can fund projects that are listed
- Project owners can withdraw funds once the project target has been reached
- Project owners can close funding for their projects: This will result in the project owners being unable to withdraw the funds and funders can request for refunds if this occurs
- Users can request and process refunds from closed projects if their target was not reached.
- There is a programmable time limit before a fund can be closed after being opened - For the purpose of testing, this has been put at around 12 minutes though ideally this would be a duration of 30 days or 60 days 

#### Areas that can be improved
- Limits can be placed on how much project owners can contribute to their own projects
- The project would be more suitable using a frontend framework/library. This is due to the conditional rendering used here makes the code look clunky and harder to maintain. Furthermore, this design tries to implement a single page application which would be better implemented with react and  would  not compromise on the user's experience particularly in the further details sections(particulary when requesting refund and processing refund). In future migration to react would be ideal.

### Usage
1. Install the [CeloExtensionWallet](https://chrome.google.com/webstore/detail/celoextensionwallet/kkilomkmpmkbdnfelcpgckmpcaemjcdh?hl=en) from the google chrome store.
2. Create a wallet.
3. Go to [https://celo.org/developers/faucet](https://celo.org/developers/faucet) and get tokens for the alfajores testnet.
4. Switch to the alfajores testnet in the CeloExtensionWallet.

### Install

```

npm install

```

or 

```

yarn install

```

### Start

```

npm run dev

```

# Build

```

npm run build

```
