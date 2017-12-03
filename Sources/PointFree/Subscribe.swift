import Foundation
import HttpPipeline
import Prelude

typealias SubscribeData = (plan: Stripe.Plan.Id, token: String)

let subscribeResponse: Middleware<StatusLineOpen, ResponseEnded, SubscribeData, Data> =
  subscribe

private func subscribe(_ conn: Conn<StatusLineOpen, SubscribeData>) -> IO<Conn<ResponseEnded, Data>> {

  return AppEnvironment.current.stripe.createCustomer(conn.data.token)
    .flatMap { customer in
      AppEnvironment.current.stripe.createSubscription(customer.id, conn.data.plan)
    }
    .run
    .flatMap { subscription -> IO<Conn<ResponseEnded, Data>> in

      switch subscription {
      case .left:
        return conn
          |> writeStatus(.internalServerError)
          >-> respond(text: "Error creating subscription!")

      case let .right(sub):
        return conn
          |> writeStatus(.created)
          >-> respond(text: "Created subscription! id: " + sub.id)
      }
  }
}