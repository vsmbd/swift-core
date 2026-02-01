# SwiftCore Non-goals

## No logging framework
- SwiftCore emits signals, it does not log or export them

## No persistence or storage
- No files, databases, or key-value stores

## No automatic error capture
- Arbitrary Error values are not serialized
- Errors must explicitly opt into reporting

## No scheduling policy
- SwiftCore provides queues, not workload management

## No UI or application logic
- Pure infrastructure only
