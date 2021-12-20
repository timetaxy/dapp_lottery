module.exports = async (promise)=>{
    //fail 하지 않을 
 try {
     await promise;
     assert.fail('Expected revert not received');

 } catch (error) {
     const revertFound = error.message.search('revert')>=0;
     assert(revertFound,`Expected "revert, got ${error} instead`);

 }   
}