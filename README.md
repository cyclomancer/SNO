# SNO
*Funding and raising informed engagement with climate change research using Scenario Bonding Curves.*

**Release Note**

The most recent contract code is found in the `updates` branch, while latest to be integrated with the client is under `master`.

**Overview**

One promising use case of the augmented bonding curve (ABC) model is gamifying contribution to public goods by rewarding speculative participation that commits funds to a capital pool for public investment. Simultaneously, in cases where ABC funding targets knowledge production and data providers, the potential exists to extend the model by involving the knowledge domain or information output of the beneficiaries in the market dynamics (eg. price function, token functionality) of curve contracts.

GloPact and its demo project SNO aim to combine these exciting implications for bonding curve design in the context of climate crisis, and other global problematics that suffer from poor incentive alignment and inadequate information availability. We propose a construction called Scenario Bonding Curves (SBCs):

- Like ABCs, a scenario bonding curve has distinct price functions for buys and sells, holding a predefined fraction of buy revenue in reserve to cover the (lower) sell price, and directing the remainder to a beneficiary contract.
- The SBC's price function is mapped to a model projection of a real-world trend, such as global average temperature increase or loss of Arctic summer ice.
- Multiple SBCs that map different projections in the model spread for that phenomenon contribute to the same capital pool, whose beneficiaries are producers of relevant research and data.
- Reserve ratios vary inversely with the extremity of the projection represented, which typically corresponds to the growth rate of the price functions. Buying into a severe climate change scenario imposes higher initial commitment of funds while promising greater returns if the supply passes the inflection point of the model. From a social and ethical perspective, this is rational because anticipating more serious potential outcomes should incentivize you to contribute more to initiatives addressing it, and on the other hand signalling more urgent problems should be highly rewarded if a critical mass of the community agrees.

Though static, this basic formulation still has a number of added benefits:

- Gamifying/rewarding education about climate change scenarios as well as contribution to understanding and combating it
- Tying market behavior of curve tokens to collective expectations regarding climate change: even a purely financial speculator must base their decisions on the existence of other participants who choose to signal their beliefs with the choice of SBCs to invest in. Since the beneficiary is non-profit and some immediate loss is a prerequisite of participation, it's reasonable to assume this will always be the case.
- Exploitation of the market by eg. pump-and-dump schemes still contributes to mitigation of global climate threats, and therefore lacks downside risk for participants who believe the phenomenon is real.

However, our aim for a fully functional iteration of this system is that it be dynamic rather than static, and incorporate feedback loops from information producers into the curve markets. This could involve:

- Modifying reserve ratios to reflect updated probability of different scenarios
- Modifying price functions based on new data and models
- Providing token holders with data access, conditional payouts, or involvement in funding allocation given appropriate triggers

This structure comprises a new type of prediction (or projection) market, implementing granular bonding curves at the level of individual and domain-specific predictions. In cases where feedback included redeeming tokens for data access, it ncentivizes price signals that reflect market expectations about what data is most useful for predicting model change. Thus in addition to supplying funds to critical knowledge resources, it would also generate useful information about the phenomenon in its own right, by driving market participants to educate themselves as much as possible and make useful information purchase decisions.

Insurance is a salutary example of further use cases for this structure, that unlike a purely charitable model could sustain itself through profitability. Current insurance mechanisms, particularly flood insurance, systematically misprice risk by failing to adequately account for climate change. This leads to pathological outcomes such as continued overinvestment in waterfront real estate development and lack of incentive to pursue mitigation and adaptation initiatives. In general, how legacy insurers set rates in relation to actuarial data and financial conditions is largely opaque to subscribers and markets, creating perverse incentives. This equally affects other large-scale social goods such as healthcare, whose pricing in the United States bears seemingly no relation to material conditions or collective outcomes. Alternative insurance mechanisms based on bonding curve information markets could instead provide a responsive, transparent, and cooperative vertical between data sources, stakeholders, and markets.

**ETHDenver Proof-of-Concept Implementation**

We built a simple augmented bonding curve contract that allows for a custom exponential function and reserve ratio to determine buy and sell prices. It contributes the spread between the pricing curves to a beneficiary wallet as described above. It also includes new functionality we call `lovequit`, which contributes the entirety of reserve funds claimable with the participant's tokens to the beneficiary.