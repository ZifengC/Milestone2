import joblib
from sklearn.datasets import load_iris
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from pathlib import Path

def train():
    # 1. Load data
    iris = load_iris()
    X, y = iris.data, iris.target

    # 2. Split and Train
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    model = LogisticRegression(max_iter=200)
    model.fit(X_train, y_train)

    # 3. Save the model to the app directory
    app_dir = Path(__file__).resolve().parent.parent / "app"
    app_dir.mkdir(parents=True, exist_ok=True)
    save_path = app_dir / "model.joblib"
    joblib.dump(model, save_path)
    print(f"Model saved successfully to {save_path}")

if __name__ == "__main__":
    train()


    
