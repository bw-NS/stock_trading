module.exports = {
    networks:{
        development:{
            host:"127.0.0.1",
            port: 12537,
            network_id: "*",
            gas: 15000000,
            gasLimit: 15000000
        }
    },
    compilers: {
        solc:{
            version: "0.8.0",
        }
    }
}
