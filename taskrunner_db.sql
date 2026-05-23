-- =====================================================
-- TaskRunner Database Setup Script (PostgreSQL)
-- =====================================================

-- 1. Удаление старых таблиц (для чистого пересоздания)
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 2. Таблица users
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    login VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Таблица tasks
CREATE TABLE tasks (
    task_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    weight INTEGER NOT NULL CHECK (weight >= 1),
    done INTEGER NOT NULL DEFAULT 0 CHECK (done >= 0 AND done <= weight),
    deadline DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 4. Триггер для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 5. Вставка тестовых данных
TRUNCATE TABLE tasks CASCADE;
TRUNCATE TABLE users CASCADE;

INSERT INTO users (user_id, login, password_hash) VALUES
(1, 'alice', MD5('alice123')),
(2, 'bob', MD5('bob456')),
(3, 'carol', MD5('carol789'));
ALTER SEQUENCE users_user_id_seq RESTART WITH 4;

INSERT INTO tasks (user_id, name, description, weight, done, deadline) VALUES
(1, 'Завершить отчёт', 'Подготовить квартальный отчёт', 5, 2, '2025-06-01'),
(1, 'Купить продукты', 'Молоко, хлеб, яйца', 3, 3, '2025-05-25'),
(1, 'Пробежка', '5 км', 10, 4, '2025-05-30'),
(2, 'Написать курсовую', 'Глава 2', 8, 3, '2025-06-10'),
(2, 'Позвонить клиенту', 'Обсудить контракт', 2, 0, '2025-05-27'),
(3, 'Заняться йогой', 'Утренняя практика', 7, 7, NULL),
(3, 'Прочитать книгу', 'Чистый код', 4, 1, '2025-06-15');

-- 6. Пять запросов для отчёта

-- 6.1 SELECT с условием
SELECT name, done, weight, deadline
FROM tasks
JOIN users ON tasks.user_id = users.user_id
WHERE users.login = 'alice' AND tasks.done < tasks.weight;

-- 6.2 INSERT
INSERT INTO tasks (user_id, name, description, weight, done, deadline)
VALUES ((SELECT user_id FROM users WHERE login = 'bob'),
        'Сходить в спортзал', 'Тренировка спины', 4, 1, '2025-05-28');

-- 6.3 UPDATE
UPDATE tasks
SET done = done + 1
WHERE name = 'Пробежка' AND user_id = (SELECT user_id FROM users WHERE login = 'alice');

-- 6.4 DELETE
DELETE FROM tasks
WHERE user_id = (SELECT user_id FROM users WHERE login = 'carol')
  AND done = weight;

-- 6.5 SELECT с JOIN
SELECT u.login, t.name, t.done, t.weight,
       ROUND(t.done * 100.0 / t.weight, 2) AS progress_percent
FROM users u
JOIN tasks t ON u.user_id = t.user_id
ORDER BY u.login, t.task_id;