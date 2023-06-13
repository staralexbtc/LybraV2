// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../interfaces/IEUSD.sol";
import "./base/LybraPeUSDVaultBase.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IWstETH {
    function stEthPerToken() external view returns (uint256);

    function wrap(uint256 _stETHAmount) external returns (uint256);
}

interface Ilido {
    function submit(address _referral) external payable returns (uint256 StETH);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IPriceFeed {
    function fetchPrice() external returns (uint256);
}

contract LybraWstETHVault is LybraPeUSDVaultBase {
    constructor(address _peusd, address _config) LybraPeUSDVaultBase(_peusd, 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0, _config) {}

    function depositEtherToMint(uint256 mintAmount) external payable override {
        require(msg.value >= 1 ether, "DNL");
        Ilido lido = Ilido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

        uint256 sharesAmount = lido.submit{value: msg.value}(address(configurator));
        require(sharesAmount > 0, "ZERO_DEPOSIT");

        lido.approve(address(collateralAsset), msg.value);

        uint256 wstETHAmount = IWstETH(address(collateralAsset)).wrap(msg.value);

        depositedAsset[msg.sender] += wstETHAmount;

        if (mintAmount > 0) {
            _mintPeUSD(msg.sender, msg.sender, mintAmount, getAssetPrice());
        }

        emit DepositEther(msg.sender, address(collateralAsset), msg.value,wstETHAmount, block.timestamp);
    }

    function getAssetPrice() public override returns (uint256) {
        uint etherPrice = IPriceFeed(0x4c517D4e2C851CA76d7eC94B805269Df0f2201De).fetchPrice();
        return (etherPrice * IWstETH(address(collateralAsset)).stEthPerToken()) / 1e18;
    }
}
