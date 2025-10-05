
# kipu-bank Leandro Avendaño

# Caracteristicas del contrato

Los usuarios pueden depositar tokens nativos (ETH) en una bóveda personal.

Los usuarios pueden retirar fondos de su bóveda, pero solo hasta un umbral fijo por transacción, representado por una variable immutable.

El contrato impone un límite global de depósitos (bankCap), definido durante el despliegue.

# Instrucciones de despliegue

1. Abrir Remix y pegar el contenido del archivo KipuBank.sol en un nuevo archivo.
2. En "Solidity compiler" selecciona el compilador
3. En la parte de "Deploy & run transaction" en Environment selecciona Injected Provider - MetaMask, el resto lo dejas igual
4. En deploy, completa bankCap con los valores que necesites, luego preciona transact y listo
5. El valor debe ingresarlo en wei

