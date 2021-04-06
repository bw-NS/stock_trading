pragma solidity >=0.5.0 <=0.8.3;

struct UserInfo{
    string Username; 
    //string UserEmail;
    bool Company;
}

contract UserManager{
    uint256 constant MAX_USER = 0xFFFFFFFF;
    address[] UserList;
    mapping(address => UserInfo) userInfo; 

    event reg_message(address addr, string Username, bool Company);
    function userRegister(address addr, string memory ali, bool company) external{
        bool _e;
        uint256 index; 
        (_e, index) = checkUserExist(addr); 
        require(!_e, "User already exist!");
        UserList.push(addr);
        UserInfo storage info = userInfo[addr];
        info.Username = ali;
        info.Company = company;
        emit reg_message(addr, userInfo[addr].Username, userInfo[addr].Company);
        
    }
    //modify later default ""
    function checkUserExist(address addr) public view returns(bool, uint256){
        for(uint256 i =0 ; i<UserList.length; i++){
            if (addr == UserList[i]){
                return (true, i);
            }
        }
        return (false, MAX_USER);
    }

    function removeUser(address addr) external{
        bool _e;
        uint256 index; 
        (_e, index) = checkUserExist(addr);
        require(_e, "addr not exist");
        UserList[index] = UserList[UserList.length-1];
        UserList.pop();
        delete userInfo[addr];
    }

    function getUsers() external view returns(address[] memory, UserInfo[] memory){
        UserInfo[] memory info = new UserInfo[](UserList.length);
        for(uint256 i = 0 ; i<UserList.length; i++){
            info[i] = userInfo[UserList[i]];
        }
        return (UserList, info);
    }

    function isCompany(address addr) external view returns(bool){
        return userInfo[addr].Company;
    }
}
