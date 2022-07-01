// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract CustomStaking is Ownable, ERC721Holder  {
    using SafeMath for uint256;

     struct StakerInformation {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenIndex;
        uint256 balance;
        uint256 rewardsEarned;
        uint256 lastUpdate;
    }

    struct NFTInformation {
        uint256 lockPeriod;
        uint256 rewards;
    }

    event NFTstaked(address owner, uint256 tokenId, uint256 lockPeriod, uint256 startDate);

    mapping(address => StakerInformation) public NFTStakers; // mappings of information of the Stacker
    mapping(uint256 => NFTInformation) NFTInfos; // mapping of information of the NFT
    mapping(uint256 => address) public tokenOwner; // link token id to token owner address
    mapping(uint256 => uint256) public tokenRewards; //mapping of the token rewards

   
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    IERC721 public nft; // NFT contract address
    IERC20 public coin; // coin contract address

       constructor(IERC721 _nft) { 
    nft = _nft;
    
  }

    uint256 private constant lockTime30 = 1 minutes;
    uint256 private constant lockTime60 = 2 minutes;
    uint256 private constant lockTime120 = 120 days;
    uint256 public constant lockTimeRewards30Days = 77 ether; // 77 coin
    uint256 public constant lockTimeRewards60Days = 777 ether; // 777 coin
    uint256 public constant lockTimeRewards120Days = 7777 ether; // 7 777 coin


    function _stake(address _user, uint256 _tokenId, uint256 _lockPeriod) internal {
      uint256 _lockPeriodUINT = _lockPeriod * 1 minutes;
      StakerInformation storage staker = NFTStakers[_user];
      require(nft.isApprovedForAll(_user, address(this)) == true, "NFT: PLEASE APPROVE THIS CONTRACT");
      require(_lockPeriodUINT >= lockTime30, "NFT: LOCK PERIOD MUST BE AT LEAST 30 DAYS");
      // if (staker.tokenIds.length > 0) {
      //   updateReward(_user);
      // }
      staker.tokenIds.push(_tokenId);
      tokenOwner[_tokenId] = _user;
      staker.tokenIndex[staker.tokenIds.length -1];
      staker.lastUpdate = block.timestamp; // on the code is Lastupdate

      NFTInformation storage _nftInfos = NFTInfos[_tokenId];
      _nftInfos.lockPeriod = block.timestamp + _lockPeriodUINT;

      if (_lockPeriodUINT == lockTime120) {
        _nftInfos.rewards = lockTimeRewards120Days;
      } else if (_lockPeriodUINT == lockTime60) {
        _nftInfos.rewards = lockTimeRewards60Days;
      } else if (_lockPeriodUINT == lockTime30) {
        _nftInfos.rewards = lockTimeRewards30Days;
      } else {
        _nftInfos.rewards = 0;
      }
      nft.safeTransferFrom(_user, address(this), _tokenId);
      emit NFTstaked(_user, _tokenId, _lockPeriodUINT, block.timestamp);

    }


    function _unstake(address _user, uint256 _tokenId) internal {
      NFTInformation storage _nftInfos = NFTInfos[_tokenId];
      StakerInformation storage staker = NFTStakers[_user];
      require(block.timestamp > _nftInfos.lockPeriod, "NFT: YOUR NFT IS STILL LOCKED");
      require(tokenOwner[_tokenId] == _user, "NFT: YOU ARE NOT THE OWNER OF THIS NFT");
      // updateReward(_user);
      
      uint256 lastIndex = staker.tokenIds.length -1;
      uint256 lastIndexKey = staker.tokenIds[lastIndex];
      uint256 tokenIdIndex = staker.tokenIndex[_tokenId];

      staker.tokenIds[tokenIdIndex] = lastIndexKey;
      staker.tokenIndex[lastIndexKey] = tokenIdIndex;
      staker.lastUpdate = block.timestamp;
      if (staker.tokenIds.length > 0) {
        for (uint256 i; i< staker.tokenIds.length; i++) {
          if (staker.tokenIds[i] == _tokenId) {
            staker.tokenIds[i] = staker.tokenIds[staker.tokenIds.length -1];
            staker.tokenIds.pop();
            break;
          }
        }
        delete staker.tokenIndex[_tokenId];
      }
      if (staker.balance == 0) {
        delete NFTStakers[_user];

      }
      delete tokenOwner[_tokenId];
      nft.safeTransferFrom(address(this), _user, _tokenId);
    }

     function unstake(uint256 _tokenId) external {
        _unstake(msg.sender, _tokenId);
    }


      function stake(uint256 _tokenId, uint256 _lockPeriod) external {
        _stake(msg.sender, _tokenId, _lockPeriod);
    }

        function getTokenInfo (uint256 _tokenId)
        external
        view
        returns (uint256 lockPeriod, uint256 rewards)
    {
        return (NFTInfos[_tokenId].lockPeriod, NFTInfos[_tokenId].rewards);
    }
}
