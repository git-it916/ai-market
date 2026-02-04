"""
Korean Market Data Service using pykrx
Provides data for KOSPI and KOSDAQ stocks
"""

import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from loguru import logger
import pandas as pd

try:
    from pykrx import stock as krx
    PYKRX_AVAILABLE = True
except ImportError:
    PYKRX_AVAILABLE = False
    logger.warning("pykrx not installed. Run: pip install pykrx")


@dataclass
class KRDataConfig:
    """Configuration for Korean market data service."""
    markets: List[str] = field(default_factory=lambda: ["KOSPI", "KOSDAQ"])
    update_interval: int = 60  # seconds
    enable_real_time: bool = True
    max_symbols: int = 100  # Limit for initial load


class KRDataService:
    """
    Korean market data service using pykrx.
    Fetches data from Korea Exchange (KRX).
    """

    def __init__(self, config: KRDataConfig = None):
        self.config = config or KRDataConfig()
        self._running = False
        self._cache: Dict[str, Dict[str, Any]] = {}
        self._all_symbols: Dict[str, Dict[str, str]] = {}  # {ticker: {name, market}}
        self._update_task: Optional[asyncio.Task] = None

        if not PYKRX_AVAILABLE:
            logger.error("pykrx is not available. Korean market data will not work.")

    async def start(self):
        """Start the data service."""
        if not PYKRX_AVAILABLE:
            logger.error("Cannot start KRDataService: pykrx not installed")
            return

        logger.info("Starting Korean Market Data Service...")
        self._running = True

        # Load all stock symbols
        await self._load_all_symbols()

        # Start update loop
        if self.config.enable_real_time:
            self._update_task = asyncio.create_task(self._update_loop())

        logger.info(f"Korean Market Data Service started with {len(self._all_symbols)} symbols")

    def stop(self):
        """Stop the data service."""
        self._running = False
        if self._update_task:
            self._update_task.cancel()
        logger.info("Korean Market Data Service stopped")

    async def _load_all_symbols(self):
        """Load all stock symbols from KOSPI and KOSDAQ."""
        try:
            today = datetime.now().strftime("%Y%m%d")

            for market in self.config.markets:
                logger.info(f"Loading {market} symbols...")

                # Run in executor to avoid blocking
                loop = asyncio.get_event_loop()
                tickers = await loop.run_in_executor(
                    None,
                    lambda: krx.get_market_ticker_list(today, market=market)
                )

                for ticker in tickers:
                    name = await loop.run_in_executor(
                        None,
                        lambda t=ticker: krx.get_market_ticker_name(t)
                    )
                    self._all_symbols[ticker] = {
                        "name": name,
                        "market": market,
                        "symbol": f"{ticker}.{'KS' if market == 'KOSPI' else 'KQ'}"
                    }

                logger.info(f"Loaded {len([s for s in self._all_symbols.values() if s['market'] == market])} {market} symbols")

            logger.info(f"Total symbols loaded: {len(self._all_symbols)}")

        except Exception as e:
            logger.error(f"Error loading symbols: {e}")

    async def _update_loop(self):
        """Background loop to update market data."""
        while self._running:
            try:
                await self._update_market_data()
                await asyncio.sleep(self.config.update_interval)
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in update loop: {e}")
                await asyncio.sleep(10)

    async def _update_market_data(self):
        """Update market data for cached symbols."""
        if not self._cache:
            return

        try:
            today = datetime.now().strftime("%Y%m%d")
            loop = asyncio.get_event_loop()

            for ticker in list(self._cache.keys())[:50]:  # Limit updates
                try:
                    ohlcv = await loop.run_in_executor(
                        None,
                        lambda t=ticker: krx.get_market_ohlcv_by_date(
                            fromdate=(datetime.now() - timedelta(days=5)).strftime("%Y%m%d"),
                            todate=today,
                            ticker=t
                        )
                    )

                    if not ohlcv.empty:
                        latest = ohlcv.iloc[-1]
                        self._cache[ticker] = {
                            "ticker": ticker,
                            "name": self._all_symbols.get(ticker, {}).get("name", "Unknown"),
                            "market": self._all_symbols.get(ticker, {}).get("market", "Unknown"),
                            "open": float(latest["시가"]),
                            "high": float(latest["고가"]),
                            "low": float(latest["저가"]),
                            "close": float(latest["종가"]),
                            "volume": int(latest["거래량"]),
                            "change": float(latest.get("등락률", 0)) if "등락률" in latest else 0,
                            "timestamp": datetime.now().isoformat()
                        }
                except Exception as e:
                    logger.warning(f"Error updating {ticker}: {e}")

        except Exception as e:
            logger.error(f"Error updating market data: {e}")

    def get_all_symbols(self) -> Dict[str, Dict[str, str]]:
        """Get all loaded symbols."""
        return self._all_symbols

    def get_kospi_symbols(self) -> List[str]:
        """Get all KOSPI ticker codes."""
        return [k for k, v in self._all_symbols.items() if v["market"] == "KOSPI"]

    def get_kosdaq_symbols(self) -> List[str]:
        """Get all KOSDAQ ticker codes."""
        return [k for k, v in self._all_symbols.items() if v["market"] == "KOSDAQ"]

    async def get_stock_data(self, ticker: str, days: int = 30) -> Optional[pd.DataFrame]:
        """
        Get historical OHLCV data for a stock.

        Args:
            ticker: Stock ticker code (e.g., "005930" for Samsung)
            days: Number of days of history

        Returns:
            DataFrame with OHLCV data
        """
        if not PYKRX_AVAILABLE:
            return None

        try:
            loop = asyncio.get_event_loop()
            today = datetime.now()
            start_date = (today - timedelta(days=days)).strftime("%Y%m%d")
            end_date = today.strftime("%Y%m%d")

            ohlcv = await loop.run_in_executor(
                None,
                lambda: krx.get_market_ohlcv_by_date(start_date, end_date, ticker)
            )

            if ohlcv.empty:
                return None

            # Rename columns to English
            ohlcv.columns = ["Open", "High", "Low", "Close", "Volume"]

            # Add to cache
            if not ohlcv.empty:
                latest = ohlcv.iloc[-1]
                self._cache[ticker] = {
                    "ticker": ticker,
                    "name": self._all_symbols.get(ticker, {}).get("name", "Unknown"),
                    "market": self._all_symbols.get(ticker, {}).get("market", "Unknown"),
                    "open": float(latest["Open"]),
                    "high": float(latest["High"]),
                    "low": float(latest["Low"]),
                    "close": float(latest["Close"]),
                    "volume": int(latest["Volume"]),
                    "timestamp": datetime.now().isoformat()
                }

            return ohlcv

        except Exception as e:
            logger.error(f"Error getting stock data for {ticker}: {e}")
            return None

    async def get_current_price(self, ticker: str) -> Optional[Dict[str, Any]]:
        """Get current price for a stock."""
        if ticker in self._cache:
            return self._cache[ticker]

        # Fetch fresh data
        df = await self.get_stock_data(ticker, days=5)
        if df is not None and ticker in self._cache:
            return self._cache[ticker]

        return None

    async def get_market_cap_top(self, market: str = "KOSPI", top_n: int = 50) -> List[Dict[str, Any]]:
        """
        Get top stocks by market cap.

        Args:
            market: "KOSPI" or "KOSDAQ"
            top_n: Number of top stocks to return
        """
        if not PYKRX_AVAILABLE:
            return []

        try:
            loop = asyncio.get_event_loop()
            today = datetime.now().strftime("%Y%m%d")

            cap_df = await loop.run_in_executor(
                None,
                lambda: krx.get_market_cap_by_ticker(today, market=market)
            )

            if cap_df.empty:
                return []

            # Sort by market cap and get top N
            cap_df = cap_df.sort_values("시가총액", ascending=False).head(top_n)

            result = []
            for ticker in cap_df.index:
                name = self._all_symbols.get(ticker, {}).get("name", "Unknown")
                result.append({
                    "ticker": ticker,
                    "name": name,
                    "market": market,
                    "market_cap": int(cap_df.loc[ticker, "시가총액"]),
                    "close": int(cap_df.loc[ticker, "종가"]),
                    "volume": int(cap_df.loc[ticker, "거래량"])
                })

            return result

        except Exception as e:
            logger.error(f"Error getting market cap data: {e}")
            return []

    async def search_stock(self, query: str) -> List[Dict[str, str]]:
        """
        Search stocks by name or ticker.

        Args:
            query: Search query (name or ticker code)

        Returns:
            List of matching stocks
        """
        query = query.upper()
        results = []

        for ticker, info in self._all_symbols.items():
            if query in ticker or query in info["name"].upper():
                results.append({
                    "ticker": ticker,
                    "name": info["name"],
                    "market": info["market"],
                    "symbol": info["symbol"]
                })

        return results[:20]  # Limit results


# Factory function
def create_kr_data_service(config: KRDataConfig = None) -> KRDataService:
    """Create Korean market data service."""
    return KRDataService(config)
