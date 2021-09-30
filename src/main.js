import Web3 from "web3";
import { newKitFromWeb3 } from "@celo/contractkit";
import BigNumber from "bignumber.js";
import crowdfundAbi from "../contract/abis/crowdfund.abi.json";
import erc20Abi from "../contract/abis/erc20.abi.json";

const ERC20_DECIMALS = 18;
const CFContractAddress = "0x87625B3788d641a10a31a250A85658BB9Dfbf24c";
const cUSDContractAddress = "0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1";

const currentWindow = window.location.href;
let kit;
let contract;
let projects = [];

const connectCeloWallet = async function () {
  if (window.celo) {
    try {
      notification("⚠️ Please approve this DApp to use it.");
      await window.celo.enable();
      notificationOff();

      const web3 = new Web3(window.celo);
      kit = newKitFromWeb3(web3);

      const accounts = await kit.web3.eth.getAccounts();
      kit.defaultAccount = accounts[0];

      contract = new kit.web3.eth.Contract(crowdfundAbi, CFContractAddress);
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
  } else {
    notification("⚠️ Please install the CeloExtensionWallet.");
  }
};

async function approve(_price) {
  const cUSDContract = new kit.web3.eth.Contract(erc20Abi, cUSDContractAddress);

  const result = await cUSDContract.methods
    .approve(MPContractAddress, _price)
    .send({ from: kit.defaultAccount });
  
  return result;
}

const getBalance = async function () {
  const totalBalance = await kit.getTotalBalance(kit.defaultAccount);
  const cUSDBalance = totalBalance.cUSD.shiftedBy(-ERC20_DECIMALS).toFixed(2);
  document.querySelector("#balance").textContent = cUSDBalance;
};

const getProjects = async function () {
  const _projectsLength = await contract.methods.getProjectCount().call();
  const _projects = [];

  for (let i = 0; i < _projectsLength; i++) {
    let _project = new Promise(async (resolve, reject) => {
      let p = await contract.methods.getProject(i).call();
      resolve({
        index: i,
        owner: p[0],
        name: p[1],
        image: p[2],
        description: p[3],
        website: p[4],
        target: new BigNumber(p[5]),
        minContrib: new BigNumber(p[6]),
        totalFunded: new BigNumber(p[7]),
        fundersCount: p[8],
        timestamp: p[9],
        funded: p[10],
        fundingOpen: p[11],
      });
    });
    _projects.push(_project);
  }
  projects = await Promise.all(_projects);
  renderProjects();
};

function renderProjects() {
  document.getElementById("catalogue").innerHTML = "";
  projects.forEach((_project) => {
    const newDiv = document.createElement("div");
    newDiv.className = "col-md-4";
    newDiv.innerHTML = projectTemplate(_project);
    document.getElementById("catalogue").appendChild(newDiv);
  });
}

function identiconTemplate(_address, shape) {
  const icon = blockies
    .create({
      seed: _address,
      size: 8,
      scale: 16,
    })
    .toDataURL();

  return `
  <div class="${shape} overflow-hidden d-inline-block border border-white border-2 shadow-sm m-0">
    <a href="https://alfajores-blockscout.celo-testnet.org/address/${_address}/transactions"
        target="_blank">
        <img src="${icon}" width="48" alt="${_address}">
    </a>
  </div>
  `;
}

function projectTemplate(_project) {
  return `
    <div class="card mb-4">
      <img class="card-img-top" src="${_project.image}" alt="...">
      <div class="position-absolute top-0 end-0 bg-warning mt-4 px-2 py-1 rounded-start">
        ${_project.fundersCount} Funders
      </div>
      <div class="card-body text-left p-4 position-relative">
      <div class="translate-middle-y position-absolute top-0">
        ${identiconTemplate(_project.owner, "rounded-circle")}
      </div>
      <h2 class="card-title fs-4 fw-bold mt-2">${_project.name}</h2>
      <p class="card-text mb-4" style="min-height: 82px">
        ${_project.description}         
      </p>
      <p class="card-text mt-4">
        <i class="bi bi-globe"></i>
        <span><a href=${
          _project.website
        } target="_blank" rel="noopener noreferrer">Project Website</a></span>
      </p>
      <div class="d-grid gap-2">
        <a id="viewDetails" class="btn btn-lg btn-outline-dark fs-6 p-3">
          Full Details
        </a>
      </div>
    </div>
  </div>
`;
}

function renderProjectDetails() {
  document.getElementById("mainContainer").style.display = "none";
  document.getElementById("subContainer").style.display = "block";
  document.getElementById("subContainer").innerHTML = "";
  projects.forEach((_project) => {
    document.title = _project.name;
    document.body.scrollTop = 0;  // Scroll to Top - For Safari
    document.documentElement.scrollTop = 0;   // Scroll to Top - For Chrome, Firefox, IE & Opera
    const newDiv = document.createElement("div");
    newDiv.innerHTML = projectDetailsTemplate(_project);
    document.getElementById("subContainer").appendChild(newDiv);
  }); 
}

function projectDetailsTemplate(_project) {
  let projectDate = new Date(_project.timestamp * 1000).toUTCString();
  
  // let styleSheet = `
  //   @media only screen and (min-width: 770px) {
  //     .closeDetails {
  //       position: sticky;
  //       top: 5.5rem;
  //     }
  //   }
  // `
  // let style = document.createElement('style');
  // style.innerHTML = styleSheet;
  // document.head.appendChild(style);

  return `
    <a class="btn btn-lg btn-light btn-dark" title="Go Back">
      <i class="bi bi-chevron-double-left closeDetails"></i>
    </a>
    </br>
    </br>
    <div class="row">
      <div class="col-md-4">
        <img class="img-fluid" src="${_project.image}" alt="...">
        <p>
          <h3>${_project.name}</h3>
          <span><b>Posted</b>: ${projectDate}</span>
        </p>
        <p class="mt-4">
          <i class="bi bi-globe"></i>
          <span><a href=${
            _project.website
          } target="_blank" rel="noopener noreferrer">Project Website</a></span>
        </p>
      </div>
      <div class="col-md-8">
        <div class="row" style="min-height: 150px">
          <div class="col-md-2">
            ${identiconTemplate(_project.owner, "border")}
          </div>
          <div class="col-md-8">
            ${_project.description}
          </div>
        </div>
        <hr style="border-top: 1px solid">
        <div class="row">
          <div class="col-md-12">
            <b>Target:</b> ${_project.target.shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
          </div>
          <div class="col-md-6">
            <b>Minimum Contribution:</b> ${_project.minContrib.shiftedBy(-ERC20_DECIMALS).toFixed(2)} cUSD
          </div>
          <div class="col-md-6">
            <b>Total Funders:</b> ${_project.fundersCount}
          </div>
        </div>
        <hr style="border-top: 1px solid">
        <div class="row">
          <div class="col-md-6">
            <b>Accepting Funding:</b> ${_project.fundingOpen ? "Yes" : "No"}
          </div>
          <div class="col-md-6">
            <b>Funding Target Reached:</b> ${_project.funded ? "Yes" : "No"}
          </div>
        </div>
        ${_project.fundingOpen && _project.funded == false ? 
          `<hr style="border-top: 1px solid">
          <div class="row">
            <div class="col-md-12">
              <label for="fundRange">Fund Project</label>
              <input type="range" class="form-range fundingRange" min="${_project.minContrib.shiftedBy(-ERC20_DECIMALS).toFixed(2)}" max="${_project.target.shiftedBy(-ERC20_DECIMALS).toFixed(2)}" value="${_project.minContrib.shiftedBy(-ERC20_DECIMALS).toFixed(2)}" id="fundRange">
              <input type="text" readonly id="rangeVal" value="${_project.minContrib.shiftedBy(-ERC20_DECIMALS).toFixed(2)}">
              </br>
              </br>
              <a class="btn btn-lg btn-outline-dark fundBtn fs-6 p-3" id=${_project.index}>
                Fund Project
              </a>
            </div>
          </div>`
          : 
          `<hr style="border-top: 1px solid">`
        }
        </br>
        </br>
      </div>
    </div>
  `;
}

function notification(_text) {
  document.querySelector(".alert").style.display = "block";
  document.querySelector("#notification").textContent = _text;
}

function notificationOff() {
  document.querySelector(".alert").style.display = "none";
}

window.addEventListener("load", async () => {
  notification("⌛ Loading...");
  await connectCeloWallet();
  await getBalance();
  await getProjects();
  notificationOff();
});

document
  .querySelector("#newProjectBtn")
  .addEventListener("click", async (e) => {
    const params = [
      document.getElementById("newProjectName").value,
      document.getElementById("newImgUrl").value,
      document.getElementById("newProjectDescription").value,
      document.getElementById("newWebsite").value,
      new BigNumber(document.getElementById("newTarget").value)
        .shiftedBy(ERC20_DECIMALS)
        .toString(),
      new BigNumber(document.getElementById("newMinContrib").value)
        .shiftedBy(ERC20_DECIMALS)
        .toString(),
    ];
    notification(`⌛ Adding "${params[0]}"...`);
    try {
      const result = await contract.methods
        .createProject(...params)
        .send({ from: kit.defaultAccount })
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
    notification(`🎉 You successfully added "${params[0]}".`);
    getProjects();
  });

document.querySelector("#catalogue").addEventListener("click", async (e) => {
  if(e.target.id.includes("viewDetails"))
    renderProjectDetails();
});

document.querySelector("#subContainer").addEventListener("click", async (e) => {
  if(e.target.className.includes("closeDetails")) {
    document.title = "Crowdfund";
    document.getElementById("mainContainer").style.display = "block";
    document.getElementById("subContainer").style.display = "none";
  }

  document.querySelector(".fundingRange").oninput = function (e) {
    document.getElementById("rangeVal").value = e.target.value;
  }

  if (e.target.className.includes("fundBtn")) {
    const index = e.target.id;
    const price = new BigNumber(document.getElementById("rangeVal").value)
      .shiftedBy(ERC20_DECIMALS)
      .toString();
    
    notification("⌛ Waiting for payment approval...");
    
    try {
      await approve(price);
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
    
    notification(`⌛ Awaiting payment for "${projects[index].name}"...`);
    
    try {
      const result = await contract.methods
        .fundProject(index, price)
        .send({ from: kit.defaultAccount });
      notification(`🎉 You successfully bought "${projects[index].name}".`);
      getprojects();
      getBalance();
    } catch (error) {
      notification(`⚠️ ${error}.`);
    }
  }
});