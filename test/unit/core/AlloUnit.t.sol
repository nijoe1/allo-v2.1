// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, stdStorage, StdStorage} from "forge-std/Test.sol";
import {IAllo} from "contracts/core/interfaces/IAllo.sol";
import {IRegistry} from "contracts/core/interfaces/IRegistry.sol";
import {MockMockAllo} from "test/smock/MockMockAllo.sol";
import {Errors} from "contracts/core/libraries/Errors.sol";
import {Metadata} from "contracts/core/libraries/Metadata.sol";
import {IBaseStrategy} from "contracts/strategies/IBaseStrategy.sol";
import {ClonesUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {LibString} from "solady/utils/LibString.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AlloUnit is Test {
    using LibString for uint256;
    using stdStorage for StdStorage;

    MockMockAllo allo;
    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    address public fakeRegistry;
    address public fakeStrategy;
    IAllo.Pool public fakePool;

    event PoolMetadataUpdated(uint256 indexed poolId, Metadata metadata);
    event RegistryUpdated(address _registry);
    event TreasuryUpdated(address payable _treasury);
    event PercentFeeUpdated(uint256 _percentFee);
    event BaseFeeUpdated(uint256 _baseFee);
    event TrustedForwarderUpdated(address _trustedForwarder);
    event PoolCreated(
        uint256 indexed poolId,
        bytes32 indexed profileId,
        IBaseStrategy strategy,
        address token,
        uint256 amount,
        Metadata metadata
    );

    function setUp() public virtual {
        allo = new MockMockAllo();
        fakeStrategy = makeAddr("fakeStrategy");
        fakePool = IAllo.Pool({
            profileId: keccak256("profileId"),
            strategy: IBaseStrategy(fakeStrategy),
            token: address(1),
            metadata: Metadata({pointer: "", protocol: 1}),
            adminRole: keccak256("adminRole"),
            managerRole: keccak256("managerRole")
        });

        fakeRegistry = makeAddr("fakeRegistry");

        vm.prank(address(0));
        allo.transferOwnership(address(this));
        allo.updateRegistry(fakeRegistry);
    }

    function test_InitializeGivenUpgradeVersionIsCorrect(
        address _owner,
        address _registry,
        address payable _treasury,
        uint256 _percentFee,
        uint256 _baseFee,
        address _trustedForwarder
    ) external {
        allo.mock_call__updateRegistry(_registry);
        allo.mock_call__updateTreasury(_treasury);
        allo.mock_call__updatePercentFee(_percentFee);
        allo.mock_call__updateBaseFee(_baseFee);
        allo.mock_call__updateTrustedForwarder(_trustedForwarder);

        // it should call _initializeOwner
        allo.expectCall__initializeOwner(_owner);

        // it should call _updateRegistry
        allo.expectCall__updateRegistry(_registry);

        // it should call _updateTreasury
        allo.expectCall__updateTreasury(_treasury);

        // it should call _updatePercentFee
        allo.expectCall__updatePercentFee(_percentFee);

        // it should call _updateBaseFee
        allo.expectCall__updateBaseFee(_baseFee);

        // it should call _updateTrustedForwarder
        allo.expectCall__updateTrustedForwarder(_trustedForwarder);

        allo.initialize(_owner, _registry, _treasury, _percentFee, _baseFee, _trustedForwarder);
    }

    function test_CreatePoolWithCustomStrategyRevertWhen_StrategyIsZeroAddress(
        bytes32 _profileId,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);

        allo.createPoolWithCustomStrategy(
            _profileId, address(0), _initStrategyData, _token, _amount, _metadata, _managers
        );
    }

    function test_CreatePoolWithCustomStrategyWhenCallingWithProperParams(
        address _creator,
        uint256 _msgValue,
        bytes32 _profileId,
        IBaseStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers,
        uint256 _poolId
    ) external {
        vm.assume(address(_strategy) != address(0));
        vm.assume(_creator != address(0));
        allo.mock_call__createPool(
            _creator,
            _msgValue,
            _profileId,
            _strategy,
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers,
            _poolId
        );

        // it should call _createPool
        allo.expectCall__createPool(
            _creator, _msgValue, _profileId, _strategy, _initStrategyData, _token, _amount, _metadata, _managers
        );

        deal(_creator, _msgValue);
        vm.prank(_creator);
        uint256 poolId = allo.createPoolWithCustomStrategy{value: _msgValue}(
            _profileId, address(_strategy), _initStrategyData, _token, _amount, _metadata, _managers
        );

        // it should return poolId
        assertEq(poolId, _poolId);
    }

    function test_CreatePoolRevertWhen_StrategyIsZeroAddress(
        bytes32 _profileId,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);

        allo.createPool(_profileId, address(0), _initStrategyData, _token, _amount, _metadata, _managers);
    }

    function test_CreatePoolWhenCallingWithProperParams(
        address _creator,
        uint256 _msgValue,
        bytes32 _profileId,
        IBaseStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers,
        uint256 _poolId
    ) external {
        vm.assume(address(_strategy) != address(0));
        vm.assume(_creator != address(0));

        address _expectedClonedStrategy = ClonesUpgradeable.predictDeterministicAddress(
            address(_strategy), keccak256(abi.encodePacked(_creator, uint256(0))), address(allo)
        );

        allo.mock_call__createPool(
            _creator,
            _msgValue,
            _profileId,
            IBaseStrategy(_expectedClonedStrategy),
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers,
            _poolId
        );

        // it should call _createPool
        allo.expectCall__createPool(
            _creator,
            _msgValue,
            _profileId,
            IBaseStrategy(_expectedClonedStrategy),
            _initStrategyData,
            _token,
            _amount,
            _metadata,
            _managers
        );

        deal(_creator, _msgValue);
        vm.prank(_creator);
        uint256 poolId = allo.createPool{value: _msgValue}(
            _profileId, address(_strategy), _initStrategyData, _token, _amount, _metadata, _managers
        );

        // it should return poolId
        assertEq(poolId, _poolId);
    }

    function test_UpdatePoolMetadataGivenSenderIsManagerOfPool(uint256 _poolId, Metadata memory _metadata) external {
        allo.mock_call__checkOnlyPoolManager(_poolId, address(this));

        // it should call _checkOnlyPoolManager
        allo.expectCall__checkOnlyPoolManager(_poolId, address(this));

        // it should emit event
        vm.expectEmit(true, true, true, true);
        emit PoolMetadataUpdated(_poolId, _metadata);

        allo.updatePoolMetadata(_poolId, _metadata);

        // it should update metadata
        assertEq(allo.getPool(_poolId).metadata.pointer, _metadata.pointer);
        assertEq(allo.getPool(_poolId).metadata.protocol, _metadata.protocol);
    }

    function test_UpdateRegistryRevertWhen_SenderIsNotOwner(address _caller, address _registry) external {
        // owner is set to this
        vm.assume(_caller != address(this));

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updateRegistry(_registry);
    }

    function test_UpdateRegistryWhenSenderIsOwner(address _registry) external {
        allo.mock_call__updateRegistry(_registry);

        // it should call _updateRegistry
        allo.expectCall__updateRegistry(_registry);

        vm.prank(address(this));
        allo.updateRegistry(_registry);
    }

    function test_UpdateTreasuryRevertWhen_SenderIsNotOwner(address _caller, address payable _treasury) external {
        // owner is set to this
        vm.assume(_caller != address(this));

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updateTreasury(_treasury);
    }

    function test_UpdateTreasuryWhenSenderIsOwner(address payable _treasury) external {
        allo.mock_call__updateTreasury(_treasury);

        // it should call _updateTreasury
        allo.expectCall__updateTreasury(_treasury);

        // owner is set to this
        vm.prank(address(this));
        allo.updateTreasury(_treasury);
    }

    function test_UpdatePercentFeeRevertWhen_SenderIsNotOwner(address _caller, uint256 _percentFee) external {
        // owner is set to this
        vm.assume(_caller != address(this));

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updatePercentFee(_percentFee);
    }

    function test_UpdatePercentFeeWhenSenderIsOwner(uint256 _percentFee) external {
        allo.mock_call__updatePercentFee(_percentFee);

        // it should call _updatePercentFee
        allo.expectCall__updatePercentFee(_percentFee);

        // owner is this
        vm.prank(address(this));
        allo.updatePercentFee(_percentFee);
    }

    function test_UpdateBaseFeeRevertWhen_SenderIsNotOwner(address _caller, uint256 _baseFee) external {
        // owner is set to this
        vm.assume(_caller != address(this));

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updateBaseFee(_baseFee);
    }

    function test_UpdateBaseFeeWhenSenderIsOwner(uint256 _baseFee) external {
        allo.mock_call__updateBaseFee(_baseFee);

        // it should call _updateBaseFee
        allo.expectCall__updateBaseFee(_baseFee);

        vm.prank(address(this));
        allo.updateBaseFee(_baseFee);
    }

    function test_UpdateTrustedForwarderRevertWhen_SenderIsNotOwner(address _caller, address _trustedForwarder)
        external
    {
        // owner is set to this 
        vm.assume(_caller != address(this));

        // it should revert
        vm.expectRevert(Ownable.Unauthorized.selector);

        vm.prank(_caller);
        allo.updateTrustedForwarder(_trustedForwarder);
    }

    function test_UpdateTrustedForwarderWhenSenderIsOwner(address _trustedForwarder) external {
        allo.mock_call__updateTrustedForwarder(_trustedForwarder);

        // it should call _updateTrustedForwarder
        allo.expectCall__updateTrustedForwarder(_trustedForwarder);

        // owner is set to this
        vm.prank(address(this));
        allo.updateTrustedForwarder(_trustedForwarder);
    }

    function test_AddPoolManagersGivenSenderIsAdminOfPoolId(uint256 _poolId, address[] memory _managers) external {
        allo.mock_call__checkOnlyPoolAdmin(_poolId, address(this));
        for (uint256 i = 0; i < _managers.length; i++) {
            allo.mock_call__addPoolManager(_poolId, _managers[i]);
        }

        // it should call _checkOnlyPoolAdmin
        allo.expectCall__checkOnlyPoolAdmin(_poolId, address(this));

        // it should call _addPoolManager
        for (uint256 i = 0; i < _managers.length; i++) {
            allo.expectCall__addPoolManager(_poolId, _managers[i]);
        }

        allo.addPoolManagers(_poolId, _managers);
    }

    function test_RemovePoolManagersGivenSenderIsAdminOfPoolId(uint256 _poolId, address[] memory _managers) external {
        allo.mock_call__checkOnlyPoolAdmin(_poolId, address(this));

        // it should call _checkOnlyPoolAdmin
        allo.expectCall__checkOnlyPoolAdmin(_poolId, address(this));

        bytes32 _role = allo.getPool(_poolId).managerRole;

        // it should call _revokeRole
        for (uint256 i = 0; i < _managers.length; i++) {
            allo.expectCall__revokeRole(_role, _managers[i]);
        }

        allo.removePoolManagers(_poolId, _managers);
    }

    function test_AddPoolManagersInMultiplePoolsGivenSenderIsAdminOfAllPoolIds(uint256[] memory _poolIds) external {
        vm.assume(_poolIds.length > 0);
        vm.assume(_poolIds.length < 100);

        address[] memory _managers = new address[](_poolIds.length);
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.mock_call__checkOnlyPoolAdmin(_poolIds[i], address(this));
            _managers[i] = makeAddr((i + 1).toString());
        }

        // it should call addPoolManagers
        // NOTE: we cant expect addPoolManagers because is a public function.
        // instead we expect the internal that is called inside addPoolManagers
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.expectCall__addPoolManager(_poolIds[i], _managers[i]);
        }

        allo.addPoolManagersInMultiplePools(_poolIds, _managers);
    }

    function test_RemovePoolManagersInMultiplePoolsGivenSenderIsAdminOfAllPoolIds(uint256[] memory _poolIds) external {
        vm.assume(_poolIds.length > 0);
        vm.assume(_poolIds.length < 100);

        address[] memory _managers = new address[](_poolIds.length);
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.mock_call__checkOnlyPoolAdmin(_poolIds[i], address(this));
            _managers[i] = makeAddr((i + 1).toString());
        }

        // it should call removePoolManagers
        // NOTE: we cant expect removePoolManagers because is a public function.
        // instead we expect the internal that is called inside removePoolManagers
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.expectCall__revokeRole(allo.getPool(_poolIds[i]).managerRole, _managers[i]);
        }

        allo.removePoolManagersInMultiplePools(_poolIds, _managers);
    }

    function test_RecoverFundsRevertWhen_SenderIsNotOwner(address _caller, address _recipient) external {
        vm.assume(_caller != address(this));

        vm.expectRevert(Ownable.Unauthorized.selector);
        // it should revert
        vm.prank(_caller);
        allo.recoverFunds(NATIVE, _recipient);
    }

    modifier whenSenderIsOwner(address _caller) {
        vm.assume(_caller != address(0));
        vm.prank(address(this));
        allo.transferOwnership(_caller);
        _;
    }

    function test_RecoverFundsWhenTokenIsNative(address _caller, address _recipient)
        external
        whenSenderIsOwner(_caller)
    {
        vm.assume(_recipient != address(0));

        deal(address(allo), 100 ether);

        assertEq(_recipient.balance, 0);
        vm.prank(_caller);
        allo.recoverFunds(NATIVE, _recipient);
        // it should transfer native token
        assertEq(_recipient.balance, 100 ether);
        assertEq(address(allo).balance, 0);
    }

    function test_RecoverFundsWhenTokenIsNotNative(address _caller, address _token, address _recipient)
        external
        whenSenderIsOwner(_caller)
    {
        vm.assume(_token != NATIVE);
        vm.assume(_recipient != address(0));

        uint256 _tokenBalance = 10 ether;
        vm.mockCall(_token, abi.encodeWithSelector(IERC20.balanceOf.selector, address(allo)), abi.encode(_tokenBalance));
        vm.mockCall(
            _token, abi.encodeWithSelector(IERC20.transfer.selector, _recipient, _tokenBalance), abi.encode(true)
        );

        // it should transfer the tokens
        vm.expectCall(_token, abi.encodeWithSelector(IERC20.balanceOf.selector, address(allo)));
        vm.expectCall(_token, abi.encodeWithSelector(IERC20.transfer.selector, _recipient, _tokenBalance));

        vm.prank(_caller);
        allo.recoverFunds(_token, _recipient);
    }

    function test_RegisterRecipientShouldCallRegisterOnTheStrategy(uint256 _poolId, bytes memory _data) external {
        address[] memory _recipients = new address[](1);
        _recipients[0] = address(1);

        allo.setPool(_poolId, fakePool);

        vm.mockCall(
            fakeStrategy,
            abi.encodeWithSelector(IBaseStrategy.register.selector, _recipients, _data, address(this)),
            abi.encode(_recipients)
        );
        // it should call register on the strategy
        vm.expectCall(
            fakeStrategy, abi.encodeWithSelector(IBaseStrategy.register.selector, _recipients, _data, address(this))
        );

        // it should return recipientId
        address[] memory _recipientIds = allo.registerRecipient(_poolId, _recipients, _data);
        assertEq(_recipientIds[0], _recipients[0]);
    }

    function test_BatchRegisterRecipientRevertWhen_PoolIdLengthDoesNotMatch_dataLength(
        uint256[] memory _poolIds,
        bytes[] memory _data
    ) external {
        vm.assume(_poolIds.length != _data.length);

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        // it should revert
        vm.expectRevert(Errors.MISMATCH.selector);

        allo.batchRegisterRecipient(_poolIds, _recipients, _data);
    }

    function test_BatchRegisterRecipientRevertWhen_PoolIdLengthDoesNotMatch_recipientsLength(
        address[][] memory _recipients
    ) external {
        vm.assume(_recipients.length != 1);

        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;
        bytes[] memory _data = new bytes[](1);
        _data[0] = "data";
        // it should revert
        vm.expectRevert(Errors.MISMATCH.selector);

        allo.batchRegisterRecipient(_poolIds, _recipients, _data);
    }

    function test_BatchRegisterRecipientWhenPoolIdLengthMatches_dataLengthAnd_recipientsLength() external {
        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        bytes[] memory _data = new bytes[](1);
        _data[0] = "data";

        allo.setPool(_poolIds[0], fakePool);

        vm.mockCall(
            fakeStrategy,
            abi.encodeWithSelector(IBaseStrategy.register.selector, _recipients[0], _data[0], address(this)),
            abi.encode(_recipients[0])
        );
        // it should call register on the strategy
        vm.expectCall(
            fakeStrategy,
            abi.encodeWithSelector(IBaseStrategy.register.selector, _recipients[0], _data[0], address(this))
        );
        // it should return recipientIds
        address[][] memory _recipientIds = allo.batchRegisterRecipient(_poolIds, _recipients, _data);
        assertEq(_recipientIds[0][0], _recipients[0][0]);
    }

    function test_FundPoolRevertWhen_AmountIsZero(uint256 _poolId) external {
        // it should revert
        vm.expectRevert(Errors.NOT_ENOUGH_FUNDS.selector);

        allo.fundPool(_poolId, 0);
    }

    function test_FundPoolRevertWhen_TokenIsNativeAndValueDoesNotMatchAmount(uint256 _poolId, uint256 _amount)
        external
    {
        vm.assume(_amount > 0);

        fakePool.token = NATIVE;

        allo.setPool(_poolId, fakePool);
        // it should revert
        vm.expectRevert(Errors.NOT_ENOUGH_FUNDS.selector);
        allo.fundPool(_poolId, _amount);
    }

    function test_FundPoolWhenCalledWithProperParams(uint256 _poolId, uint256 _amount) external {
        vm.assume(_amount > 0);
        fakePool.token = makeAddr("token");
        allo.setPool(_poolId, fakePool);

        allo.mock_call__fundPool(_amount, address(this), _poolId, fakePool.strategy);
        // it should call _fundPool
        allo.expectCall__fundPool(_amount, address(this), _poolId, fakePool.strategy);
        allo.fundPool(_poolId, _amount);
    }

    function test_AllocateShouldCallAllocate(
        uint256 _poolId,
        address[] memory _recipients,
        uint256[] memory _amounts,
        bytes memory _data
    ) external {
        allo.mock_call__allocate(_poolId, _recipients, _amounts, _data, 0, address(this));
        // it should call _allocate
        allo.expectCall__allocate(_poolId, _recipients, _amounts, _data, 0, address(this));
        allo.allocate(_poolId, _recipients, _amounts, _data);
    }

    function test_BatchAllocateRevertWhen_PoolIdLengthDoesNotMatch_dataLength(
        bytes[] memory _datas
    ) external {
        vm.assume(_datas.length != 1);

        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        uint256[][] memory _amounts = new uint256[][](1);
        _amounts[0] = new uint256[](1);
        _amounts[0][0] = 1;

        uint256[] memory _values = new uint256[](1);
        _values[0] = 1;

        // it should revert
        vm.expectRevert(Errors.MISMATCH.selector);
        allo.batchAllocate(_poolIds, _recipients, _amounts, _values, _datas);
    }

    function test_BatchAllocateRevertWhen_PoolIdLengthDoesNotMatch_valuesLength(
        uint256[] memory _values
    ) external {
        vm.assume(_values.length != 1);

        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        uint256[][] memory _amounts = new uint256[][](1);
        _amounts[0] = new uint256[](1);
        _amounts[0][0] = 1;

        bytes[] memory _datas = new bytes[](1);
        _datas[0] = "data";

        // it should revert
        vm.expectRevert(Errors.MISMATCH.selector);
        allo.batchAllocate(_poolIds, _recipients, _amounts, _values, _datas);
    }

    function test_BatchAllocateRevertWhen_PoolIdLengthDoesNotMatch_recipientsLength(
        address[][] memory _recipients
    ) external {
        vm.assume(_recipients.length != 1);

        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        uint256[][] memory _amounts = new uint256[][](1);
        _amounts[0] = new uint256[](1);
        _amounts[0][0] = 1;

        uint256[] memory _values = new uint256[](1);
        _values[0] = 1;

        bytes[] memory _datas = new bytes[](1);
        _datas[0] = "data";

        // it should revert
        vm.expectRevert(Errors.MISMATCH.selector);
        allo.batchAllocate(_poolIds, _recipients, _amounts, _values, _datas);
    }

    function test_BatchAllocateRevertWhen_PoolIdLengthDoesNotMatch_amountsLength(
        uint256[][] memory _amounts
    ) external {
        vm.assume(_amounts.length != 1);
        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        uint256[] memory _values = new uint256[](1);
        _values[0] = 1;

        bytes[] memory _datas = new bytes[](1);
        _datas[0] = "data";

        // it should revert
        vm.expectRevert(Errors.MISMATCH.selector);
        allo.batchAllocate(_poolIds, _recipients, _amounts, _values, _datas);
    }

    function test_BatchAllocateWhenLengthsMatches() external {
        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        uint256[][] memory _amounts = new uint256[][](1);
        _amounts[0] = new uint256[](1);
        _amounts[0][0] = 1;

        uint256[] memory _values = new uint256[](1);
        _values[0] = 0;

        bytes[] memory _datas = new bytes[](1);
        _datas[0] = "data";

        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.mock_call__allocate(_poolIds[i], _recipients[i], _amounts[i], _datas[i], _values[i], address(this));
        }

        // it should call allocate
        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.expectCall__allocate(_poolIds[i], _recipients[i], _amounts[i], _datas[i], _values[i], address(this));
        }

        allo.batchAllocate(_poolIds, _recipients, _amounts, _values, _datas);
    }

    function test_BatchAllocateRevertWhen_TotalValueDoesNotMatchValue() external {
        uint256[] memory _poolIds = new uint256[](1);
        _poolIds[0] = 1;

        address[][] memory _recipients = new address[][](1);
        _recipients[0] = new address[](1);
        _recipients[0][0] = address(1);

        uint256[][] memory _amounts = new uint256[][](1);
        _amounts[0] = new uint256[](1);

        uint256[] memory _values = new uint256[](1);
        _values[0] = 1;

        bytes[] memory _datas = new bytes[](1);
        _datas[0] = "data";

        for (uint256 i = 0; i < _poolIds.length; i++) {
            allo.mock_call__allocate(_poolIds[i], _recipients[i], _amounts[i], _datas[i], _values[i], address(this));
        }

        // it should revert
        vm.expectRevert(Errors.ETH_MISMATCH.selector);
        allo.batchAllocate(_poolIds, _recipients, _amounts, _values, _datas);
    }

    function test_DistributeShouldCallDistributeOnTheStrategy(
        uint256 _poolId,
        address[] memory _recipients,
        bytes memory _data
    ) external {
        allo.setPool(_poolId, fakePool);

        vm.mockCall(
            fakeStrategy,
            abi.encodeWithSelector(IBaseStrategy.distribute.selector, _recipients, _data, address(this)),
            abi.encode()
        );
        // it should call distribute on the strategy
        vm.expectCall(
            fakeStrategy, abi.encodeWithSelector(IBaseStrategy.distribute.selector, _recipients, _data, address(this))
        );

        allo.distribute(_poolId, _recipients, _data);
    }

    modifier givenSenderIsAdminOfPoolId(uint256 _poolId) {
        allo.mock_call__checkOnlyPoolAdmin(_poolId, address(this));
        _;
    }

    function test_ChangeAdminRevertWhen_NewAdminIsZeroAddress(uint256 _poolId)
        external
        givenSenderIsAdminOfPoolId(_poolId)
    {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);
        allo.changeAdmin(_poolId, address(0));
    }

    function test_ChangeAdminWhenNewAdminIsNotZeroAddress(uint256 _poolId, address _newAdmin)
        external
        givenSenderIsAdminOfPoolId(_poolId)
    {
        vm.assume(_newAdmin != address(0));
        // it should call _checkOnlyPoolAdmin
        allo.expectCall__checkOnlyPoolAdmin(_poolId, address(this));
        // it should call _revokeRole
        allo.expectCall__revokeRole(allo.getPool(_poolId).adminRole, address(this));
        // it should call _grantRole
        allo.expectCall__grantRole(allo.getPool(_poolId).adminRole, _newAdmin);

        allo.changeAdmin(_poolId, _newAdmin);
    }

    function test__checkOnlyPoolManagerShouldCall_isPoolManager(uint256 _poolId, address _poolManager) external {
        // it should call _isPoolManager
        allo.mock_call__isPoolManager(_poolId, _poolManager, true);
        allo.expectCall__isPoolManager(_poolId, _poolManager);

        allo.call__checkOnlyPoolManager(_poolId, _poolManager);
    }

    function test__checkOnlyPoolManagerRevertWhen_IsNotPoolManager(uint256 _poolId, address _poolManager) external {
        // it should revert
        allo.mock_call__isPoolManager(_poolId, _poolManager, false);
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        allo.call__checkOnlyPoolManager(_poolId, _poolManager);
    }

    function test__checkOnlyPoolAdminShouldCall_isPoolAdmin(uint256 _poolId, address _poolAdmin) external {
        // it should call _isPoolAdmin
        allo.mock_call__isPoolAdmin(_poolId, _poolAdmin, true);
        allo.expectCall__isPoolAdmin(_poolId, _poolAdmin);

        allo.call__checkOnlyPoolAdmin(_poolId, _poolAdmin);
    }

    function test__checkOnlyPoolAdminRevertWhen_IsNotPoolAdmin(uint256 _poolId, address _poolAdmin) external {
        // it should revert
        allo.mock_call__isPoolAdmin(_poolId, _poolAdmin, false);
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        allo.call__checkOnlyPoolAdmin(_poolId, _poolAdmin);
    }

    function test__createPoolWhenCalledValidParams(
        bytes32 _profileId,
        IBaseStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        Metadata memory _metadata,
        address[] memory _managers
    ) external {
        vm.mockCall(
            fakeRegistry,
            abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profileId, address(this)),
            abi.encode(true)
        );

        uint256 poolId = 1;
        bytes32 POOL_MANAGER_ROLE = bytes32(poolId);
        bytes32 POOL_ADMIN_ROLE = keccak256(abi.encodePacked(poolId, "admin"));

        // it should grant admin role to creator
        allo.mock_call__grantRole(POOL_ADMIN_ROLE, address(this));
        allo.expectCall__grantRole(POOL_ADMIN_ROLE, address(this));
        // it should set admin role to pool manager
        allo.mock_call__setRoleAdmin(POOL_MANAGER_ROLE, POOL_ADMIN_ROLE);
        allo.expectCall__setRoleAdmin(POOL_MANAGER_ROLE, POOL_ADMIN_ROLE);
        // it should save pool on pools mapping
        // it should call initialize on the strategy
        vm.mockCall(
            fakeStrategy,
            abi.encodeWithSelector(IBaseStrategy.initialize.selector, poolId, _initStrategyData),
            abi.encode()
        );
        vm.expectCall(
            fakeStrategy, abi.encodeWithSelector(IBaseStrategy.initialize.selector, poolId, _initStrategyData)
        );
        vm.mockCall(
            fakeStrategy,
            abi.encodeWithSelector(IBaseStrategy.getPoolId.selector),
            abi.encode(poolId)
        );
        vm.mockCall(
            fakeStrategy,
            abi.encodeWithSelector(IBaseStrategy.getAllo.selector),
            abi.encode(address(allo))
        );
        // it should add pool managers
        for(uint256 i = 0; i < _managers.length; i++) {
            allo.mock_call__addPoolManager(poolId, _managers[i]);
            allo.expectCall__addPoolManager(poolId, _managers[i]);
        }
        // it should emit PoolCreated event
        vm.expectEmit(true, true, true, true);
        emit PoolCreated(poolId, _profileId, IBaseStrategy(fakeStrategy), _token, 0, _metadata);

        allo.call__createPool(
            address(this), 0, _profileId, IBaseStrategy(fakeStrategy), _initStrategyData, _token, 0, _metadata, _managers
        );
    }

    function test__createPoolRevertWhen_IsNotOwnerOrMemberOfProfile(
        address _creator,
        uint256 _msgValue,
        bytes32 _profileId,
        IBaseStrategy _strategy,
        bytes memory _initStrategyData,
        address _token,
        uint256 _amount,
        Metadata memory _metadata,
        address[] memory _managers
    ) external {
        vm.mockCall(
            fakeRegistry,
            abi.encodeWithSelector(IRegistry.isOwnerOrMemberOfProfile.selector, _profileId, _creator),
            abi.encode(false)
        );
        // it should revert
        vm.expectRevert(Errors.UNAUTHORIZED.selector);

        allo.call__createPool(
            _creator, _msgValue, _profileId, _strategy, _initStrategyData, _token, _amount, _metadata, _managers
        );
    }

    function test__createPoolRevertWhen_StrategyPoolIdDoesNotMatch() external {
        // it should revert
        vm.skip(true);
    }

    function test__createPoolRevertWhen_AlloAddressDoesNotMatch() external {
        // it should revert
        vm.skip(true);
    }

    modifier whenBaseFeeIsMoreThanZero() {
        _;
    }

    modifier whenTokenIsNative() {
        _;
    }

    function test__createPoolRevertWhen_BaseFeePlusAmountIsDiffFromValue()
        external
        whenBaseFeeIsMoreThanZero
        whenTokenIsNative
    {
        // it should revert
        vm.skip(true);
    }

    modifier whenTokenIsNotNative() {
        _;
    }

    function test__createPoolRevertWhen_BaseFeeIsDiffFromValue()
        external
        whenBaseFeeIsMoreThanZero
        whenTokenIsNotNative
    {
        // it should revert
        vm.skip(true);
    }

    function test__createPoolWhenProvidedFeeIsCorrect() external whenBaseFeeIsMoreThanZero {
        // it should call _transferAmount
        // it should emit event
        vm.skip(true);
    }

    function test__createPoolWhenAmountIsMoreThanZero() external {
        // it should call _fundPool
        vm.skip(true);
    }

    // TODO: fix
    function test__allocateShouldCallAllocateOnTheStrategy(
        uint256 _poolId,
        // address[] memory _recipients,
        // uint256[] memory _amounts,
        // bytes memory _data,
        uint256 _value,
        address _allocator
    ) external {
        vm.skip(true);
        deal(address(this), _value);
        allo.setPool(_poolId, fakePool);

        address[] memory _recipients = new address[](1);
        _recipients[0] = address(1);

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = 1;

        bytes memory _data = "0x";

        vm.mockCall(
            fakeStrategy,
            abi.encodeWithSelector(IBaseStrategy.allocate.selector, _recipients, _amounts, _data, _allocator),
            abi.encode()
        );
        // it should call allocate on the strategy
        vm.expectCall(
            fakeStrategy, abi.encodeWithSelector(IBaseStrategy.allocate.selector, _recipients, _amounts, _data, _allocator)
        );

        allo.call__allocate(_poolId, _recipients, _amounts, _data, _value, _allocator);
    }

    modifier whenPercentFeeIsMoreThanZero() {
        _;
    }

    function test__fundPoolWhenPercentFeeIsMoreThanZero() external whenPercentFeeIsMoreThanZero {
        // it should call getFeeDenominator
        vm.skip(true);
    }

    function test__fundPoolRevertWhen_FeeAmountPlusAmountAfterFeeDiffAmount() external whenPercentFeeIsMoreThanZero {
        // it should revert
        vm.skip(true);
    }

    function test__fundPoolWhenTokenIsNative() external whenPercentFeeIsMoreThanZero {
        // it should call _transferAmountFrom
        vm.skip(true);
    }

    function test__fundPoolWhenTokenIsNotNative() external whenPercentFeeIsMoreThanZero {
        // it should call _getBalance
        // it should call _transferAmountFrom
        vm.skip(true);
    }

    function test__fundPoolWhenTokenIsNativeToken() external {
        // it should call _transferAmountFrom
        vm.skip(true);
    }

    function test__fundPoolWhenTokenIsNotNativeToken() external {
        // it should call _getBalance
        // it should call _transferAmountFrom
        vm.skip(true);
    }

    function test__fundPoolShouldCallIncreasePoolAmountOnTheStrategy() external {
        // it should call increasePoolAmount on the strategy
        vm.skip(true);
    }

    function test__fundPoolShouldEmitEvent() external {
        // it should emit event
        vm.skip(true);
    }

    function test__isPoolAdminWhenHasRoleAdmin(uint256 _poolId, address _poolAdmin) external {
        allo.mock_call__isPoolAdmin(_poolId, _poolAdmin, true);
        // it should return true
        assertTrue(allo.call__isPoolAdmin(_poolId, _poolAdmin));
    }

    function test__isPoolAdminWhenHasNoRoleAdmin(uint256 _poolId, address _poolAdmin) external {
        // it should return false
        assertTrue(!allo.call__isPoolAdmin(_poolId, _poolAdmin));
    }

    function test__isPoolManagerWhenHasRoleManager(uint256 _poolId, address _poolManager) external {
        vm.assume(_poolManager != address(0));
        allo.call__addPoolManager(_poolId, _poolManager);
        // it should return true
        assertTrue(allo.call__isPoolManager(_poolId, _poolManager));
    }

    function test__isPoolManagerWhenHasRoleAdmin(uint256 _poolId, address _poolManager) external {
        allo.mock_call__isPoolAdmin(_poolId, _poolManager, true);
        // it should return true
        assertTrue(allo.call__isPoolManager(_poolId, _poolManager));
    }

    function test__isPoolManagerWhenHasNoRolesAtAll(uint256 _poolId, address _poolManager) external {
        // it should return false
        assertTrue(!allo.call__isPoolManager(_poolId, _poolManager));
    }

    function test__updateRegistryRevertWhen_RegistryIsZeroAddress() external {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);
        allo.call__updateRegistry(address(0));
    }

    function test__updateRegistryGivenRegistryIsNotZeroAddress(address _newRegistry) external {
        vm.assume(_newRegistry != address(0));
        // it should update registry
        assertEq(address(allo.getRegistry()), fakeRegistry);
        // it should emit event
        vm.expectEmit(true, true, true, true);
        emit RegistryUpdated(_newRegistry);

        allo.call__updateRegistry(_newRegistry);
        assertEq(address(allo.getRegistry()), _newRegistry);
    }

    function test__updateTreasuryRevertWhen_TreasuryIsZeroAddress() external {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);
        allo.call__updateTreasury(payable(0));
    }

    function test__updateTreasuryGivenTreasuryIsNotZeroAddress(address payable _newTreasury) external {
        vm.assume(_newTreasury != address(0));
        // it should update treasury
        assertEq(allo.getTreasury(), address(0));
        // it should emit event
        vm.expectEmit(true, true, true, true);
        emit TreasuryUpdated(_newTreasury);

        allo.call__updateTreasury(_newTreasury);
        assertEq(allo.getTreasury(), _newTreasury);
    }

    function test__updatePercentFeeRevertWhen_PercentFeeIsMoreThan1e18() external {
        // it should revert
        vm.expectRevert(Errors.INVALID_FEE.selector);
        allo.call__updatePercentFee(1e18 + 1);
    }

    function test__updatePercentFeeGivenPercentFeeIsValid(uint256 _percentFee) external {
        _percentFee = bound(_percentFee, 1, 1e18);
        // it should update percentFee
        assertEq(allo.getPercentFee(), 0);
        // it should emit event
        vm.expectEmit(true, true, true, true);
        emit PercentFeeUpdated(_percentFee);

        allo.call__updatePercentFee(_percentFee);
        assertEq(allo.getPercentFee(), _percentFee);
    }

    function test__updateBaseFeeShouldUpdateBaseFee(uint256 _baseFee) external {
        // it should update baseFee
        assertEq(allo.getBaseFee(), 0);
        allo.call__updateBaseFee(_baseFee);

        assertEq(allo.getBaseFee(), _baseFee);
    }

    function test__updateBaseFeeShouldEmitEvent(uint256 _baseFee) external {
        // it should emit event
        vm.expectEmit(true, true, true, true);
        emit BaseFeeUpdated(_baseFee);

        allo.call__updateBaseFee(_baseFee);
    }

    function test__updateTrustedForwarderShouldUpdateTrustedForwarder(address _trustedForwarder) external {
        // it should update trustedForwarder
        assertEq(allo.isTrustedForwarder(address(0)), true);
        allo.call__updateTrustedForwarder(_trustedForwarder);

        assertEq(allo.isTrustedForwarder(_trustedForwarder), true);
    }

    function test__updateTrustedForwarderShouldEmitEvent(address _trustedForwarder) external {
        // it should emit event
        vm.expectEmit(true, true, true, true);
        emit TrustedForwarderUpdated(_trustedForwarder);

        allo.call__updateTrustedForwarder(_trustedForwarder);
    }

    function test__addPoolManagerRevertWhen_ManagerIsZeroAddress(uint256 _poolId) external {
        // it should revert
        vm.expectRevert(Errors.ZERO_ADDRESS.selector);
        allo.call__addPoolManager(_poolId, address(0));
    }

    function test__addPoolManagerGivenManagerIsNotZeroAddress(uint256 _poolId, address _poolManager) external {
        vm.assume(_poolManager != address(0));
        // it should call _grantRole
        allo.expectCall__grantRole(allo.getPool(_poolId).managerRole, _poolManager);

        allo.call__addPoolManager(_poolId, _poolManager);
    }

    modifier whenSenderIsTrustedForwarder() {
        _;
    }

    function test__msgSenderWhenCalldataLengthIsMoreThan20() external whenSenderIsTrustedForwarder {
        // it should return actual sender
        vm.skip(true);
    }

    function test__msgSenderWhenConditionsAreNotMet() external {
        // it should call _msgSender
        vm.skip(true);
    }

    function test__msgDataWhenCalldataLengthIsMoreThan20() external whenSenderIsTrustedForwarder {
        // it should return actual data
        vm.skip(true);
    }

    function test__msgDataWhenConditionsAreNotMet() external {
        // it should call _msgData
        vm.skip(true);
    }

    function test_GetFeeDenominatorShouldReturnFeeDenominator() external {
        // it should return feeDenominator
        assertEq(allo.getFeeDenominator(), 1e18);
    }

    function test_IsPoolAdminShouldCall_isPoolAdmin(uint256 _poolId, address _poolAdmin) external {
        // it should call _isPoolAdmin
        allo.expectCall__isPoolAdmin(_poolId, _poolAdmin);
        allo.mock_call__isPoolAdmin(_poolId, _poolAdmin, false);
        bool res = allo.isPoolAdmin(_poolId, _poolAdmin);
        assertEq(res, false);
    }

    function test_IsPoolAdminShouldReturnIsPoolAdmin(uint256 _poolId, address _poolAdmin) external {
        // it should return isPoolAdmin
        allo.mock_call__isPoolAdmin(_poolId, _poolAdmin, true);
        bool res = allo.isPoolAdmin(_poolId, _poolAdmin);
        assertEq(res, true);
    }

    function test_IsPoolManagerShouldCall_isPoolManager(uint256 _poolId, address _poolManager) external {
        // it should call _isPoolManager
        allo.expectCall__isPoolManager(_poolId, _poolManager);
        allo.mock_call__isPoolManager(_poolId, _poolManager, false);
        bool res = allo.isPoolManager(_poolId, _poolManager);
        assertEq(res, false);
    }

    function test_IsPoolManagerShouldReturnIsPoolManager(uint256 _poolId, address _poolManager) external {
        // it should return isPoolManager
        allo.mock_call__isPoolManager(_poolId, _poolManager, true);
        bool res = allo.isPoolManager(_poolId, _poolManager);
        assertEq(res, true);
    }

    function test_GetStrategyShouldReturnStrategy() external {
        // it should return strategy
        vm.skip(true);
    }

    function test_GetPercentFeeShouldReturnPercentFee(uint256 _percentFee) external {
        _percentFee = bound(_percentFee, 0, 1e18);
        // it should return percentFee
        allo.call__updatePercentFee(_percentFee);
        assertEq(allo.getPercentFee(), _percentFee);
    }

    function test_GetBaseFeeShouldReturnBaseFee(uint256 _baseFee) external {
        _baseFee = bound(_baseFee, 0, 1e18);
        // it should return baseFee
        allo.call__updateBaseFee(_baseFee);
        assertEq(allo.getBaseFee(), _baseFee);
    }

    function test_GetTreasuryShouldReturnTreasury(address _treasury) external {
        vm.assume(_treasury != address(0));
        // it should return treasury
        allo.call__updateTreasury(payable(_treasury));
        assertEq(allo.getTreasury(), _treasury);
    }

    function test_GetRegistryShouldReturnRegistry(address _registry) external {
        vm.assume(_registry != address(0));
        // it should return registry
        allo.call__updateRegistry(_registry);
        assertEq(address(allo.getRegistry()), _registry);
    }

    function test_GetPoolShouldReturnPool() external {
        // it should return pool
        vm.skip(true);
    }

    function test_IsTrustedForwarderWhenForwarderIsTrustedForwarder(address _trustedForwarder) external {
        // it should return true
        allo.call__updateTrustedForwarder(_trustedForwarder);
        assertEq(allo.isTrustedForwarder(_trustedForwarder), true);
    }

    function test_IsTrustedForwarderWhenForwarderIsNotTrustedForwarder(address _trustedForwarder) external {
        vm.assume(_trustedForwarder != address(0));
        // it should return false
        assertEq(allo.isTrustedForwarder(_trustedForwarder), false);
    }
}
