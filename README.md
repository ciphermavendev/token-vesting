# Token Vesting Smart Contract

This repository contains a flexible and secure token vesting smart contract implementation built with Solidity and Hardhat.

## Features

- Customizable vesting schedules with cliff periods
- Multiple beneficiary support
- Revocable vesting schedules
- Token release mechanism
- Comprehensive test coverage
- Security features (reentrancy protection, ownership controls)

## Installation

```bash
npm install
```

## Configuration

1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Update the environment variables in `.env`:
```
PRIVATE_KEY=your_private_key
NETWORK_URL=your_network_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## Testing

Run the test suite:

```bash
npx hardhat test
```

## Deployment

1. Update the deployment configuration in `hardhat.config.js`
2. Run deployment script:

```bash
npx hardhat run scripts/deploy.js --network <network-name>
```

## Contract Interaction

### Creating a Vesting Schedule

```javascript
const schedule = await tokenVesting.createVestingSchedule(
    beneficiaryAddress,
    startTimestamp,
    cliffDuration,
    vestingDuration,
    amount,
    revocable
);
```

### Releasing Tokens

```javascript
const scheduleId = await tokenVesting.computeVestingScheduleId(beneficiaryAddress, startTimestamp);
await tokenVesting.release(scheduleId);
```

### Revoking a Schedule

```javascript
await tokenVesting.revoke(scheduleId);
```

## Security

This project uses OpenZeppelin contracts for secure implementation of standard functionalities. The contracts have been developed following Solidity best practices and security patterns.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request