const fs = require("fs");
let accounts = JSON.parse(fs.readFileSync("./accounts.json"));

const saveAccountData = () => {
  fs.writeFile("./accounts.json", JSON.stringify(accounts), err => {
    if (err) {
      console.log("error while saving account data!");
      console.log(err);
    } else {
      console.log("Saved Account Data");
    }
  });
};

const withdraw = (ammount, username, account) => {
  if (accounts[username] != undefined) {
    try {
      if (account[username].accounts[account] != undefined) {
        account[username].accounts[account] -= ammount
        console.log("Withdrawn " + ammount + " from " + username + " 's " + account + " account");
        return "Ammount Withdrawn";
      } else {
        return "Account Undefined";
      }
    } catch (error) {
      console.log("Error withdrawing " + ammount + " from " + username + " 's " + account + " account");
      console.log(error);
      return "Error Withdrawing Ammount";
    }
  } else {
    return "User Undefined";
  }
}

const deposit = (ammount, username, account) => {
  if (accounts[username] != undefined) {
    try {
      if (account[username].accounts[account] != undefined) {
        accounts[username].accounts[account] += ammount;
        console.log("Deposited " + ammount + " into " + username + " 's " + account + " account");
        return "Ammount Sent";
      } else {
        return "Account Underfined"
      }
    } catch (error) {
      console.log("Error depositing " + ammount + " into " + username + " 's " + account + " account");
      console.log(error);
      return "Error Depositing Ammount";
    }
  } else {
    return "User Undefined";
  }
};

const send = (ammount, senderUsername, senderAccount, receivingUsername, recevingAccount) => {
  if (accounts[senderUsername] != undefined) {
    let withdrawOutput = withdraw(ammount, senderUsername, senderAccount)
    if (withdrawOutput == "Ammount Withdrawn") {} else {
      return `Error Withdrawing Ammount From Sender For Reason : ${withdrawOutput}`;
    }
    let depositOutput = deposit(ammount, receivingUsername, recevingAccount);
    if (depositOutput == "Ammount Sent") {
      console.log("Sent " + ammount + " into " + receivingUsername + " 's " + recevingAccount + " account from " + senderUsername + " 's " + account + " account");
      return "Ammount Sent";
    } else {
      let depositOutput2 = deposit(ammount, senderUsername, senderAccount);
      if (depositOutput2 == "Ammount Sent") {
        return "Returned Ammount To Sender After Failure To Send Ammount To Recipiant";
      } else {
        console.log("Failed to return " + ammount + " into " + senderUsername + " 's " + senderAccount + " account after trying to transer " + ammount + " into " + receivingUsername + " 's " + account + " account");
        return "Failed To Return Ammount To Sender After Failure To Send Ammount To Recipiant. Please Contact A System Admin";
      }
    }
  } else {
    return "Sender's Account Username Not Found";
  };
};

setInterval(saveAccountData, 10000);