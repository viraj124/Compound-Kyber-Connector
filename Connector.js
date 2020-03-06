import React, { Component } from 'react';
import logo from '../logo.png';
import Web3 from 'web3';
import './App.css';

class App extends Component {

  constructor(props) {
    super(props);
    this.state = {
      account: ''
    }
  }

  async componentWillMount() {
    await this.loadWeb3()
    await this.loadBlockchainData()
  }

  async loadWeb3() {
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum)
      await window.ethereum.enable()
    }
    else if (window.web3) {
      window.web3 = new Web3(window.web3.currentProvider)
    }
    else {
      window.alert('Non-Ethereum browser detected. You should consider trying MetaMask!')
    }
  }

  async loadBlockchainData() {
    const web3 = window.web3
     
var kyber_compound_leverage = {
      "constant": false,
      "inputs": [
        {
          "name": "src",
          "type": "address"
        },
        {
          "name": "dest",
          "type": "address"
        },
        {
          "name": "srcAmt",
          "type": "uint256"
        },
        {
          "name": "maxDestAmt",
          "type": "uint256"
        },
        {
          "name": "slippageRate",
          "type": "uint256"
        },
        {
          "name": "maxAmount",
          "type": "uint256"
        },
        {
          "name": "markets",
          "type": "address[]"
        }
      ],
      "name": "leverage",
      "outputs": [
        {
          "name": "destAmt",
          "type": "uint256"
        }
      ],
      "payable": true,
      "stateMutability": "payable",
      "type": "function"
    };
      var kyber_compound_leverage_args = [
      '0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa',
      '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
      "100000000000000000000",
      "10000000000000000",
      1,
      "100000000000000000000000000000000000000",
      ["0xe7bc397dbd069fc7d0109c0636d06888bb50668c", "0xf92fbe0d3c0dcdae407923b2ac17ec223b1084e4"]
  ]

    const leverageData = await web3.eth.abi.encodeFunctionCall(kyber_compound_leverage, kyber_compound_leverage_args)
    console.log(leverageData)
    
    var kyber_compound_save = {
      "constant": false,
      "inputs": [
        {
          "name": "src",
          "type": "address"
        },
        {
          "name": "dest",
          "type": "address"
        },
        {
          "name": "srcAmt",
          "type": "uint256"
        },
        {
          "name": "maxDestAmt",
          "type": "uint256"
        },
        {
          "name": "slippageRate",
          "type": "uint256"
        },
        {
          "name": "markets",
          "type": "address[]"
        }
      ],
      "name": "save",
      "outputs": [],
      "payable": true,
      "stateMutability": "payable",
      "type": "function"
    };
      var kyber_compound_save_args = [
      '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
      '0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa',
      "100000000",
      "10000000000000000",
      1,
      ["0xe7bc397dbd069fc7d0109c0636d06888bb50668c"]
  ]

    const saveData = await web3.eth.abi.encodeFunctionCall(kyber_compound_save, kyber_compound_save_args)
    console.log(saveData)
  }

  render() {
    return (
      <div>
        Compound Connector
      </div>
    );
  }
}

export default App;
