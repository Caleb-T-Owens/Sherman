use crate::sets::InvertibleSet;

mod sets;

// #[expect(unused)]
// #[derive(PartialEq, Eq, Hash, Clone, Debug)]
// struct Message {
//     body: String,
// }

// impl From<&str> for Message {
//     fn from(value: &str) -> Self {
//         value.to_owned().into()
//     }
// }

// impl From<String> for Message {
//     fn from(value: String) -> Self {
//         Message { body: value }
//     }
// }

#[derive(Clone, Debug, Default)]
struct Node {
    messages: InvertibleSet<String>,
    dropped_messages: InvertibleSet<String>,
}

impl Node {
    fn send_message(&mut self, msg: String) {
        self.messages.insert(msg);
    }

    fn drop_message(&mut self, msg: String) {
        self.messages.remove(msg.clone());
        self.dropped_messages.insert(msg);
    }
}

impl Node {
    fn sync(lhs: &mut Self, rhs: &mut Self) {
        let new_msgs = lhs
            .messages
            .intersection(&rhs.dropped_messages.complement())
            .union(
                &rhs.messages
                    .intersection(&lhs.dropped_messages.complement()),
            );

        let dropped = lhs.dropped_messages.intersection(&rhs.dropped_messages);
        let lhs_dropped = dropped.union(&lhs.messages.intersection(&new_msgs.complement()));
        let rhs_dropped = dropped.union(&rhs.messages.intersection(&new_msgs.complement()));

        lhs.messages = new_msgs.clone();
        lhs.dropped_messages = lhs_dropped;
        rhs.messages = new_msgs;
        rhs.dropped_messages = rhs_dropped;
    }
}

fn main() {
    let mut a = Node::default();
    let mut b = Node::default();
    let mut c = Node::default();

    a.send_message("a".into());

    dbg!(("initial", &a, &b, &c));
    Node::sync(&mut a, &mut b);
    dbg!(("first", &a, &b, &c));
    Node::sync(&mut b, &mut c);
    dbg!(("second", &a, &b, &c));

    c.drop_message("a".into());

    dbg!(("dropped message", &a, &b, &c));
    Node::sync(&mut c, &mut b);
    dbg!(("first", &a, &b, &c));
    Node::sync(&mut b, &mut a);
    dbg!(("second", &a, &b, &c));
}
