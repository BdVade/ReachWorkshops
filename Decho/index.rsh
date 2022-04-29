'reach 0.1';



// export const main = Reach.App(() => {
//   const creator = Participant('Creator', {
//     approvalLimit: UInt,
//     donationLimit: UInt,
//     state: UInt,
//     name: UInt, // place holder. figure out how to return Bytes
//     url: Bytes(32),
//     approvalExpiryDate: UInt,
//     donationExpiryDate: UInt,
//     causeAccount: Address
//   });
//   const voter = Participant('Voter', {
//     amount: UInt,
//     assetID: UInt,
//     claim:Fun([], Null)
//   });
//    const checker = Participant('Checker', {
    
//    })
 
//   init();
//   creator.only(() => {
//   const approvalLimit = declassify(interact.approvalLimit)
//   const donationLimit = declassify(interact.donationLimit)
//   const state = declassify(interact.state)
//   const name = declassify(interact.name)
//   const url = declassify(interact.url)
//   const donationExpiryDate = declassify(interact.donationExpiryDate)
//   const approvalExpiryDate = declassify(interact.approvalExpiryDate)
//   const causeAccount = declassify(interact.causeAccount)})

//   creator.publish(approvalLimit, donationLimit,state, name, url, donationExpiryDate, approvalExpiryDate);
//   // checker.set(None) // An address/account. To be determined later
//   const approvals = new Map(UInt)
//  const donations = new Map(UInt)
//   commit();
//   // The second one to publish always attaches
//   voter.only(()=>{
//     const amount =  declassify(interact.amount)
//     const asset =  declassify(interact.assetID)
//   })
//   if (asset == 0){
//     voter.publish().pay(amount)
//     if (donations.has(this)){
//       approvals[this]+=amount
//     } else{
//       donations[this] = amount
//     }
//   } else{
//     voter.publish.pay([amount, asset])
    
//     if (approvals.has(this)){
//       approvals[this]+=amount
//     } else{
//       approvals[this] = amount
//     }
//   }

//   voter.publish();
//   commit();
//   // write your program here
//   //when deadline passes or balance is completed.
//   transfer(donationLimit).to(causeAccount)

//   // use map.forEach() to return modey to voters and donating people
  
//   exit();
// });

const ProjectDetails = Object({
  name:Bytes(32),
  url:Bytes(32),
  approvalLimit: UInt,
  approvalDeadline: UInt,
  donationLimit: UInt,
  donationDeadline: UInt,
  fowardingAccount: Address
  
})
export const main = Reach.App(()=>{
  const creator = Participant('Creator', {
    projectDetails: ProjectDetails
  })

  const voter = API('voter', {
    vote: Fun([UInt],Bool),
    claimFunds: Fun([], Bool)
  })

  const donator = API('donator', {
    donate: Fun([UInt], Bool),
    reclaimDonations: Fun([], Bool)
  })
  init();

  creator.only(()=>{
    const projectDetails = declassify(interact.projectDetails)
  })
  creator.publish(projectDetails);
  const {
  name,
  url,
  approvalLimit,
  approvalDeadline,
  donationLimit,
  donationDeadline,
  fowardingAccount
   } = projectDetails
  const voters_list = new Map(Address,UInt);
  const donators = new Map(Address,UInt);
  const  votesBalance = 
  parallelReduce(balance())
    .invariant(balance()>=0)
    .while(votesBalance<approvalLimit)
    .api(voter.vote, 
      ((amount) => assume(amount>0)),
      ((amount) =>  amount ),
      ((amount,setResponse) => {
        if (voters_list[this]){
          const new_balance = fromSome(voters_list[this],0) + amount
          voters_list[this] = new_balance
        } else{
          voters_list[this]=amount
        }
        setResponse(true)
        return votesBalance+amount
      }))

     .timeout(approvalDeadline, () => {
       const [voters_remaining] =
       parallelReduce([ voters.size() ]) // Voters map length
         .invariant(0==0)
         .while(voters_remaining>0)
        // find a way to loop over the map and send to all to avoid using a timeout
          .api(voter.claimFunds,
            (() => {assume(voters_list[this])}),
            (()=> pass),
            ((setResponse) => {transfer(fromSome(voters_list[this],0 )).to(this)
              setResponse(True)
                    }))
          })
     

     const [donationsBalance] = 
     parallelReduce([ balance() ])
       .invariant(balance()>=0)
       .while(donationsBalance<donationLimit)
       .api(donator.donate,
        ((amount)=> {assume(amount>0)}),
        ((amount)=>{ amount }),
        ((amount, setResponse) => {
          if (donators[this]){
              donators[this]+=amount
          } else {
            donators[this]=amount
          }
          setResponse(true)
          if (balance()>=donationLimit){
            transfer(balance()).to(fowardingAccount)
          }
        return donationsBalance+amount})
        )
        .timeout(donationDeadline, () => {
          const donators_remaining =
       parallelReduce( donators.size() ) // Voters map length
         .invariant(0==0)
         .while(donators_remaining>0)
        // find a way to loop over the map and send to all to avoid using a timeout
          .api(donator.reclaimDonations,
            (() => {assume(donators.has(this))}),
            (()=> pass),
            ((setResponse) => {transfer(donators[this]).to(this)
                    setResponse(true)
                    }))
        });
        commit();
  exit();
})