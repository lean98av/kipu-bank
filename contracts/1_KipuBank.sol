// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title KipuBank
 * @author lean98av
 * @notice Contrato bancario educativo que permite depósitos y retiros de ETH con límites y seguridad.
 * @dev Este contrato es únicamente con fines académicos.
 */
contract Bank {
    /*///////////////////////////////////
           State variables
    ///////////////////////////////////*/

    /// @notice Representa la cuenta de un usuario en el banco
    struct Account {
        uint256 balance; /// @notice Saldo actual en la cuenta
        string name;     /// @notice Nombre del titular de la cuenta
        string email;    /// @notice Email del titular de la cuenta
        bool exists;     /// @notice Indica si la cuenta está creada
    }

    /// @notice Almacena todas las cuentas de los usuarios mapeadas por su dirección
    mapping(address => Account) private accounts;

    /// @dev Flag interno para prevenir ataques de reentrancy
    bool internal locked;

    /// @notice Dirección del dueño del contrato
    address public immutable i_contractOwner;

    /// @notice Límite máximo de retiro permitido por transacción
    uint256 public immutable i_maxWithdrawAmount = 0.1 ether;

    /// @notice Capacidad máxima global de depósitos en el banco
    uint256 public immutable i_bankCap;

    /// @notice Contador de depósitos realizados en el contrato
    uint256 public s_depositCounter;

    /// @notice Contador de retiros realizados en el contrato
    uint256 public s_withdrawCounter;

    /// @notice Suma total de fondos depositados en el banco
    uint256 public s_totalBankBalance;

    /*///////////////////////////////////
               Events
    ///////////////////////////////////*/

    /// @notice Evento emitido cuando se realiza un depósito exitoso
    /// @param origin Dirección del usuario que deposita
    /// @param valor Monto depositado
    event Bank_Deposit(address indexed origin, uint256 valor);

    /// @notice Evento emitido cuando se realiza un retiro exitoso
    /// @param destination Dirección del usuario que retira
    /// @param valor Monto retirado
    event Bank_Withdraw(address indexed destination, uint256 valor);

    /*///////////////////////////////////
               Errors
    ///////////////////////////////////*/

    error Bank_AccountAlreadyExists();
    error Bank_AccountNotExists();
    error Bank_DifferentOwner();
    error Bank_ExceedBankCap();
    error Bank_ExceedWithdrawAmount();
    error Bank_InsuficientFunds();
    error Bank_InvalidDeposit();
    error Bank_NoReentrancy();
    error Bank_TransferError();

    /*///////////////////////////////////
            Functions
    ///////////////////////////////////*/

    /// @notice Constructor del contrato
    /// @param _bankCap Límite global de fondos que puede recibir el banco
    constructor(uint256 _bankCap) {
        i_contractOwner = msg.sender;
        i_bankCap = _bankCap;
    }

    /// @notice Modificador que previene ataques de reentrancy
    modifier nonReentrant() {
        if (locked) revert Bank_NoReentrancy();
        locked = true;
        _;
        locked = false;
    }

    /// @notice Crea una cuenta nueva con email y nombre, y deposita ETH inicial
    /// @param _email Email del usuario
    /// @param _name Nombre del usuario
    function createAccount(
        string memory _email,
        string memory _name
    ) public payable {
        if (accounts[msg.sender].exists) revert Bank_AccountAlreadyExists();
        if (s_totalBankBalance + msg.value > i_bankCap)
            revert Bank_ExceedBankCap();

        accounts[msg.sender] = Account({
            exists: true,
            balance: 0,
            email: _email,
            name: _name
        });

        _updateVault(msg.sender, msg.value);

        s_totalBankBalance += msg.value;
        s_depositCounter++;

        emit Bank_Deposit(msg.sender, msg.value);
    }

    /// @notice Permite a un usuario depositar ETH en su cuenta
    /// @dev Se sigue el patrón checks-effects-interactions
    function deposit() external payable {
        if (msg.value == 0) revert Bank_InvalidDeposit();
        if (s_totalBankBalance + msg.value > i_bankCap)
            revert Bank_ExceedBankCap();

        _updateVault(msg.sender, msg.value);

        s_totalBankBalance += msg.value;
        s_depositCounter++;

        emit Bank_Deposit(msg.sender, msg.value);
    }

    /// @notice Función interna que actualiza la bóveda de un usuario
    /// @param usuario Dirección del usuario
    /// @param monto Cantidad de ETH a incrementar en la cuenta
    function _updateVault(address usuario, uint256 monto) private {
        accounts[usuario].balance += monto;
    }

    /// @notice Permite a un usuario retirar ETH de su cuenta, respetando el límite máximo
    /// @param monto Cantidad a retirar en wei
    function withdraw(uint256 monto) external nonReentrant {
        if (!accounts[msg.sender].exists) revert Bank_AccountNotExists();
        if (monto > i_maxWithdrawAmount) revert Bank_ExceedWithdrawAmount();
        if (accounts[msg.sender].balance < monto) revert Bank_InsuficientFunds();

        accounts[msg.sender].balance -= monto;
        s_totalBankBalance -= monto;
        s_withdrawCounter++;

        (bool success, ) = payable(msg.sender).call{value: monto}("");
        if (!success) revert Bank_TransferError();

        emit Bank_Withdraw(msg.sender, monto);
    }

    /// @notice Devuelve el balance de una cuenta
    /// @param usuario Dirección del usuario a consultar
    /// @return Balance actual en wei
    function getBalance(address usuario) external view returns (uint256) {
        if (!accounts[usuario].exists) revert Bank_AccountNotExists();
        return accounts[usuario].balance;
    }
}
