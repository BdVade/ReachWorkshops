'reach 0.1';

export const main = Reach.App(() => {
  const Funder = Participant('Funder', {
    // Specify Alice's interact interface here
    Reciever: Address,
    amount: UInt,
    waitingTime: UInt,
    refund: UInt,
    dormant: UInt
  });

  const waitTime = Events('waitTime', {
    timeOver: [Bool]
  })
  const Reciever = Participant('Reciever', {
    // Specify Bob's interact interface here

  });
  const ByStander = Participant('ByStander', {
   
  })
  init();
  // The first one to publish deploys the contract

  Funder.only(()=>{
     const amt = declassify(interact.amount)
     const waitingTime = declassify(interact.waitingTime)
     const refund = declassify(interact.refund)
     const dormant = declassify(interact.dormant)
     const reciever = declassify(interact.Reciever)
  })
  Funder.publish(amt, waitingTime, refund, dormant, reciever).pay(amt);
  Reciever.set(reciever)
  commit();

  wait(relativeTime(waitingTime));
  waitTime.timeOver(true);
  // The second one to publish always attaches
  Reciever.publish()
  .timeout(relativeTime(refund), 
    () =>{
      Funder.publish()
        .timeout(relativeTime(dormant), () =>{
          ByStander.publish();
          transfer(amt).to(ByStander)
          commit();
          exit();
        });
        transfer(amt).to(Funder)
        commit();
        exit();
    });
    transfer(amt).to(Reciever)
  commit();
  // write your program here
  exit();
});
