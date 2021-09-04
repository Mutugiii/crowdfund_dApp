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
    uint totalContrib;
    uint timestamp;
    bool withdrawable;
  }

  // Add a deadline field
  struct Project {
    address payable owner;
    uint id;
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
    uint id,
    string name,
    string image,
    string description,
    string website,
    uint target,
    uint minContrib,
    uint timestamp
  );
  
  event FundProjectEvent(
    uint id,
    uint totalFunded,
    uint fundersCount
  );
  
  event CloseFundEvent(
    uint id,
    bool funded,
    bool fundingOpen
  );

  // Retrieve a user's contributions
  function getContributions(uint _index) external view returns (uint[] memory, uint, uint, bool) {
    Project storage project = projects[_index];
    
    require(project.exists, 'The project does not exist!');
    require(project.contributions[msg.sender].contributer == msg.sender);

    return(
      project.contributions[msg.sender].contribs,
      project.contributions[msg.sender].totalContrib,
      project.contributions[msg.sender].timestamp,
      project.contributions[msg.sender].withdrawable
    );
  }
  
  function getProjectCount () public view returns (uint) {
    return projectCount;
  }
  
  function getProject (uint _index) public view returns (
    address payable,
    uint,
    string memory,
    string memory,
    string memory,
    string memory,
    uint,
    uint,
    uint,
    uint,
    uint,
    bool
  ) {
    Project storage project = projects[_index];
    return (
      project.owner,
      project.id,
      project.name,
      project.image,
      project.description,
      project.website,
      project.target,
      project.minContrib,
      project.totalFunded,
      project.fundersCount,
      project.timestamp,
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
    require(_target > 0, 'Project target must be greater than 0 cUSD');
    require(_minContrib < _target, 'The minimum contribution must be less than the Target!');
    require(bytes(_name).length != 0 && bytes(_description).length != 0 && bytes(_website).length != 0, 'Project Title, description and website must be present!');
    
    uint _totalFunded = 0;
    uint _fundersCount = 0;
    
    Project storage newProject = projects[projectCount];
    
    newProject.owner = payable(msg.sender);
    newProject.id = projectCount;
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
      newProject.id,
      newProject.name,
      newProject.image,
      newProject.description,
      newProject.website,
      newProject.target,
      newProject.minContrib,
      newProject.timestamp
    );
  }
  
  function fundProject (uint _index, uint _amount) external payable {
    Project storage project = projects[_index];
    
    require(project.exists, 'The project does not exist!');
    require(project.minContrib > _amount, 'Provide funding greater than the mininimum contribution set');
    require(project.funded == false, 'The project has been fully funded');
    require(project.fundingOpen, 'The Project Owner has closed the Project Funding');
    require((project.totalFunded + _amount) < project.target, 'The amount contributed will lead to Overfunding');
    require(msg.sender == project.owner, 'You cannot fund your own project');
    
    // Funds are sent to the contract to act as an escrow account
    require(
      IERC20Token(cUsdTokenAddress).transfer(
        msg.sender,
        _amount
      ),
      "Funding failed."
    );
      
    // Add the funders count and the total amount funded
    if(project.contributions[msg.sender].contribs.length == 0){
      project.fundersCount++;
    }
    project.totalFunded += _amount;

    // Add the contribution data related to the sender's address
    project.contributions[msg.sender].contribs.push(_amount);
    project.contributions[msg.sender].totalContrib += _amount;
    project.contributions[msg.sender].timestamp = block.timestamp;
    project.contributions[msg.sender].withdrawable = false;
      
    // Check if Target is reached 
    if(project.totalFunded == project.target) {
      // Close the funding
      project.funded = true;
      project.fundingOpen = false;
                
      // Send the funds from escrow to the project owner if contract has enough funds
      require(project.totalFunded < address(this).balance, 'Try again later or contact support!');
      // This pattern avoids re-entrancy
      uint funds = project.totalFunded;
      delete project.totalFunded;
      project.owner.transfer(funds);  
    }
      
    // Edge Case - Check if the mininimum contribution amount is more than the target amount
    if((project.target - project.totalFunded) < project.minContrib) {
      project.minContrib = (project.target - project.totalFunded);
    }
    
    emit FundProjectEvent(
      project.id,
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
    require(block.timestamp > (project.timestamp + 12 minutes), 'The Fund cannot be closed before 12 minutes elapse');
            
    // If target has not been reached allow contributers to get a refund of their contributions
    if(project.funded == false) {
      project.contributions[msg.sender].withdrawable = true;
    }
    
    project.fundingOpen = false;

    emit CloseFundEvent(
      project.id,
      project.funded,
      project.fundingOpen
    );
  }

  // Allow contributers to be be refunded their contributions if the project is closed before funding target is reached
  function getRefund(uint _index) external payable {
    Project storage project = projects[_index];
    
    require(project.exists, 'The project does not exist!');
    require(project.contributions[msg.sender].withdrawable == true);
    require(project.contributions[msg.sender].contributer == msg.sender);
    
    // This pattern avoids potential re-entrancy
    uint totalContributions = project.contributions[msg.sender].totalContrib;
    delete project.contributions[msg.sender].totalContrib;
    delete project.contributions[msg.sender].contribs;
    payable(msg.sender).transfer(totalContributions);
  }
  
  function increaseProjectCount() internal {
    projectCount++;
  }
}