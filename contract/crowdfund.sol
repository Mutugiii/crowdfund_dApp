// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {  
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CrowdFund {
  struct contributionData {
    address contributer;
    uint[] contribs;
    uint[] timestamps;
    uint totalContrib;
    bool withdrawable;
  }

  // Add a deadline field
  struct Project {
    address payable owner;
    string name;
    string image;
    string description;
    string website;
    uint target;
    uint minContrib;
    uint totalFunded;
    uint fundersCount;
    uint timestamp;
    bool funded;
    bool fundingOpen;
    bool exists;
    
    mapping(address => contributionData) contributions;
  }
  uint internal projectCount = 0;
  mapping(uint => Project) internal projects;  
  address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
  
  modifier onlyProjectOwner(uint _index) {
    require(msg.sender == projects[_index].owner, "Only the Project Owner can call this function");
    _;
  }
    
  event AddProjectEvent(
    address indexed owner,
    string name,
    string image,
    string description,
    string website,
    uint target,
    uint minContrib,
    uint timestamp
  );
  
  event EditProjectEvent(
    address indexed owner,
    string name,
    string image,
    string description,
    string website,
    uint target,
    uint minContrib,
    uint timestamp
  );
  
  event FundProjectEvent(
    uint totalFunded,
    uint fundersCount
  );
  
  event CloseFundEvent(
    bool funded,
    bool fundingOpen
  );
  
  function getProjectCount () public view returns (uint) {
    return projectCount;
  }
  
  function getProject (uint _index) public view returns (
    address payable,
    string memory,
    string memory,
    string memory,
    string memory,
    uint,
    uint,
    uint,
    uint,
    uint,
    bool,
    bool
  ) {
    Project storage project = projects[_index];
    return (
      project.owner,
      project.name,
      project.image,
      project.description,
      project.website,
      project.target,
      project.minContrib,
      project.totalFunded,
      project.fundersCount,
      project.timestamp,
      project.funded,
      project.fundingOpen
    );
  }
  
  function createProject (
    string memory _name,
    string memory _image,
    string memory _description,
    string memory _website,
    uint _target,
    uint _minContrib
  ) public {
    // Error Handling
  validateData(
     _image,
     _description,
     _website,
     _target,
     _minContrib);

  
    uint _totalFunded = 0;
    uint _fundersCount = 0;
    
    Project storage newProject = projects[projectCount];
    
    newProject.owner = payable(msg.sender);
    newProject.name = _name;
    newProject.image = _image;
    newProject.description = _description;
    newProject.website = _website;
    newProject.target = _target;
    newProject.minContrib = _minContrib;
    newProject.totalFunded = _totalFunded;
    newProject.fundersCount = _fundersCount;
    newProject.timestamp = block.timestamp;
    newProject.funded = false;
    newProject.fundingOpen = true;
    newProject.exists = true;
    
    increaseProjectCount();
      
    emit AddProjectEvent(
      newProject.owner,
      newProject.name,
      newProject.image,
      newProject.description,
      newProject.website,
      newProject.target,
      newProject.minContrib,
      newProject.timestamp
    );
  }


// owner of the project can edit it
  function editProject (
    uint _index,
    string memory _name,
    string memory _image,
    string memory _description,
    string memory _website,
    uint _target,
    uint _minContrib
  ) public  onlyProjectOwner(_index)  {

      
    Project storage project = projects[_index];
    
    // Error Handling
      validateData(
     _image,
     _description,
     _website,
     _target,
     _minContrib);


   
    uint _totalFunded = project.totalFunded;
    uint _fundersCount = project.fundersCount;
    
    require(_target >_totalFunded, "Cannt update target to value less than already raised" );

    project.name = _name;
    project.image = _image;
    project.description = _description;
    project.website = _website;
    project.target = _target;
    project.minContrib = _minContrib;
    project.totalFunded = _totalFunded;
    project.fundersCount = _fundersCount;

    emit EditProjectEvent(
      project.owner,
      project.name,
      project.image,
      project.description,
      project.website,
      project.target,
      project.minContrib,
      project.timestamp
    );
  }
  
  
  function fundProject (uint _index, uint _amount) public payable {
    Project storage project = projects[_index];
    
    // Error Handling
    require(project.exists, 'The project does not exist!');
    require(project.funded == false, 'The project has been fully funded');
    require(project.fundingOpen, 'The Project Owner has closed the Project Funding');
    
    if(_amount <  project.minContrib) {
      revert("Provide funding greater than the mininimum contribution set");
    }
    if((project.totalFunded + _amount) > project.target) {
      revert("The amount contributed will lead to Overfunding");
    }
    
    // Funds are sent to the smart contract to act as an escrow account
    require(
      IERC20Token(cUsdTokenAddress).transferFrom(
        msg.sender,
        address(this),
        _amount
      ),
      "Funding failed."
    );
      
    // Add the funders count and the total amount funded
    if(project.contributions[msg.sender].contribs.length == 0) {
      project.fundersCount++;
    }
    project.totalFunded += _amount;

    // Add the contribution data related to the sender's address
    project.contributions[msg.sender].contribs.push(_amount);
    project.contributions[msg.sender].timestamps.push(block.timestamp);
    project.contributions[msg.sender].totalContrib += _amount;
    project.contributions[msg.sender].withdrawable = false;
      
    // Check if Target is reached 
    if(project.totalFunded == project.target) {
      // Close the funding
      project.funded = true;
      project.fundingOpen = false;  
    }
      
    // Edge Case - Check if the mininimum contribution amount is more than the target amount
    if((project.target - project.totalFunded) < project.minContrib) {
      project.minContrib = (project.target - project.totalFunded);
    }
    
    emit FundProjectEvent(
      project.totalFunded,
      project.fundersCount
    );
  }

  // Function to close project funding
  function closeFund (uint _index) public onlyProjectOwner(_index) {
    Project storage project = projects[_index];
    
    require(project.exists, 'The project does not exist!');
    require(project.fundingOpen, 'Project funding is already closed!');
    
    // 12 minutes is for testing purposes, ideally this could be 30 days or otherwise.
    if(block.timestamp < (project.timestamp + 12 minutes)) {
      revert("The Fund cannot be closed before 12 minutes elapse");
    }
    
    project.fundingOpen = false;

    emit CloseFundEvent(
      project.funded,
      project.fundingOpen
    );
  }

  // Project owner to withdraw funds
  function withdrawFunds (uint _index) public payable onlyProjectOwner(_index) {
    Project storage project = projects[_index];
    
    require(project.exists, 'The project does not exist!');
    require(project.funded, 'The project has not been fully funded');
    require(project.fundingOpen == false, 'The project is still accepting funding');

    uint funds = project.totalFunded;
    delete project.totalFunded;
    
    IERC20Token(cUsdTokenAddress).transfer(
      payable(msg.sender),
      funds
    );
  }

  // Retrieve a user's contributions
  function getContributions(uint _index) external view returns (
    uint[] memory,
    uint[] memory,
    uint,
    bool    
  ) {
    Project storage project = projects[_index];
    
    // Error Handling
    require(project.exists, 'The project does not exist!');

    return (
      project.contributions[msg.sender].contribs,
      project.contributions[msg.sender].timestamps,
      project.contributions[msg.sender].totalContrib,
      project.contributions[msg.sender].withdrawable
    );
  }

  // Allow individual users to request their own refunds if the fund was closed before the target was reached
  function requestRefund(uint _index) external returns (uint) {
    Project storage project = projects[_index];
    
    require(project.exists, 'The project does not exist!');
    require(project.fundingOpen == false, 'The project is still accepting funding!');

    if(project.funded == false) {
      project.contributions[msg.sender].withdrawable = true;
      return project.contributions[msg.sender].totalContrib;
    }

    return 0;
  }

  // Allow contributers to be be refunded their contributions if the project is closed before funding target is reached
  function getRefund(uint _index) external payable {
    Project storage project = projects[_index];
    
    require(project.exists, 'The project does not exist!');
    require(project.fundingOpen == false, 'The project is still accepting funding!');
    
    uint totalContributions = project.contributions[msg.sender].totalContrib;

    project.contributions[msg.sender].withdrawable = false;
    delete project.contributions[msg.sender].totalContrib;
    delete project.contributions[msg.sender].contribs;

    IERC20Token(cUsdTokenAddress).transfer(
      payable(msg.sender),
      totalContributions
    ); 
  }
  
  function increaseProjectCount() internal {
    projectCount++;
  }
  function validateData(
    string memory _name,
    string memory _description,
    string memory _website,
    uint _target,
    uint _minContrib  ) internal pure {
     require(_target > 0, 'Project target must be greater than 0 cUSD');
    require(_minContrib < _target, 'The minimum contribution must be less than the Target!');
    require(bytes(_name).length != 0 && bytes(_description).length != 0 && bytes(_website).length != 0, 'Project Title, description and website must be present!');
    
  }
}