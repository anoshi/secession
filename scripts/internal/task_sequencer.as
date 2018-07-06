interface Task {
	bool hasEnded() const;
	void start();
	void update(float time);
}

// --------------------------------------------
class TaskSequencer {
	protected array<Task@> m_tasks;
	protected Task@ m_activeTask;

	// --------------------------------------------
	void add(Task@ task) {
		m_tasks.insertLast(task);
	}

	// --------------------------------------------
	void update(float time) {
		if (m_tasks.size() <= 0) {
			return;
		}

		if (m_activeTask is null) {
			// start now
			@m_activeTask = m_tasks[0];
			m_activeTask.start();
		}

		// update
		// -- if active_task->start causes pre_begin_match to be ran, task manager can get cleared during that, prepare for it
		if (m_activeTask !is null) {
			m_activeTask.update(time);
		}

		if (m_activeTask !is null) {
			if (m_activeTask.hasEnded()) {
				// cleanup and forget at end
				m_tasks.removeAt(0);
				@m_activeTask = null;
			}
		}
	}

	// --------------------------------------------
	void clear() {
		m_tasks = array<Task@>();
		@m_activeTask = null;
	}
};

