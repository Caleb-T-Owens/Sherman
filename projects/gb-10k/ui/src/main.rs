use std::{
    cell::{Ref, RefCell},
    sync::{
        Arc, Mutex,
        mpsc::{Receiver, Sender, TryRecvError, channel},
    },
    time::Duration,
};

use eframe::egui::{self, Context, Ui};
// use libbut2::But;

fn main() -> eframe::Result {
    env_logger::init(); // Log to stderr (if you run with `RUST_LOG=debug`).
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default().with_inner_size([320.0, 240.0]),
        ..Default::default()
    };

    eframe::run_native(
        "gb-10k",
        options,
        Box::new(|cc| {
            // This gives us image support:
            egui_extras::install_image_loaders(&cc.egui_ctx);

            // let ctx = cc.egui_ctx.clone();
            let app = App::initalize(State { counter: 66 }, cc.egui_ctx.clone());
            Ok(Box::new(app))
        }),
    )
}

/// The state of the application.
///
/// Currently it gets cloned after every action so it can be displayed to the
/// frontend, but this is not super efficient. There is probably something
/// better that could be done, but async programming is all bullshit so this is
/// what I came up with.
#[derive(Clone)]
struct State {
    counter: u32,
}

type Action = fn(&mut State) -> ();

struct App {
    action_queue: Sender<Action>,
    current_state: Signal<State>,
}

fn my_action(state: &mut State, thing: String) {
    std::thread::sleep(Duration::from_secs(1));
    state.counter += 1;
    println!("{}", thing);
}

struct Signal<T> {
    channel: Receiver<T>,
    value: RefCell<T>,
}

impl<T> Signal<T> {
    fn get(&self) -> Ref<'_, T> {
        match self.channel.try_recv() {
            Ok(value) => {
                let mut self_value = self.value.borrow_mut();
                *self_value = value;
                drop(self_value);
                self.value.borrow()
            }
            Err(TryRecvError::Empty) => self.value.borrow(),
            _ => panic!("ahh shit"),
        }
    }
}

impl App {
    /// Perform a task asyncly by pushing it onto the Action queue for
    /// execution.
    ///
    /// Async actions are all performed on one thread in the same order they
    /// were sent.
    pub fn perform_later(&self, fun: Action) {
        self.action_queue.send(fun).unwrap();
    }

    fn initalize(initial_state: State, ctx: Context) -> Self {
        let (action_queue, action_queue_rx) = channel::<Action>();
        let state = Arc::new(Mutex::new(initial_state.clone()));
        let (state_tx, state_rx) = channel::<State>();
        let state_signal = Signal {
            value: RefCell::new(initial_state.clone()),
            channel: state_rx,
        };

        std::thread::spawn(move || {
            loop {
                let task = action_queue_rx.recv().unwrap();
                let mut state = state.lock().unwrap();
                task(&mut state);
                state_tx.send(state.clone()).unwrap();
                println!("finished a task!");
                ctx.request_repaint();
            }
        });

        Self {
            action_queue,
            current_state: state_signal,
        }
    }
}

impl eframe::App for App {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ctx, |ui| {
            Main::ui(self, ui);
        });
    }
}

struct Main;

impl Main {
    fn ui(app: &App, ui: &mut Ui) {
        let state = app.current_state.get();
        println!("Frame");
        ui.heading("Hello world!");
        if ui.button("Click me!").clicked() {
            app.perform_later(|state| my_action(state, "it's clicked".into()));
        }
        ui.heading(format!("Counter: {}", state.counter));
    }
}
