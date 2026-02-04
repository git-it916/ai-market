"""
Korean Market Routes - KOSPI and KOSDAQ data endpoints
"""

from fastapi import APIRouter, HTTPException, Query
from typing import Optional, List
from loguru import logger
from pydantic import BaseModel

from routes import dependencies


router = APIRouter(prefix="/kr", tags=["Korean Market"])


class StockInfo(BaseModel):
    ticker: str
    name: str
    market: str
    symbol: Optional[str] = None


class StockPrice(BaseModel):
    ticker: str
    name: str
    market: str
    open: float
    high: float
    low: float
    close: float
    volume: int
    change: Optional[float] = None
    timestamp: str


class MarketCapStock(BaseModel):
    ticker: str
    name: str
    market: str
    market_cap: int
    close: int
    volume: int


@router.get("/symbols", response_model=dict)
async def get_all_symbols():
    """
    Get all loaded Korean stock symbols.
    Returns KOSPI and KOSDAQ symbols.
    """
    try:
        if not dependencies.kr_data_service:
            raise HTTPException(status_code=503, detail="Korean data service not available")

        symbols = dependencies.kr_data_service.get_all_symbols()
        kospi_count = len([s for s in symbols.values() if s["market"] == "KOSPI"])
        kosdaq_count = len([s for s in symbols.values() if s["market"] == "KOSDAQ"])

        return {
            "total": len(symbols),
            "kospi_count": kospi_count,
            "kosdaq_count": kosdaq_count,
            "symbols": symbols
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting symbols: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/kospi", response_model=List[str])
async def get_kospi_symbols():
    """Get all KOSPI stock ticker codes."""
    try:
        if not dependencies.kr_data_service:
            raise HTTPException(status_code=503, detail="Korean data service not available")

        return dependencies.kr_data_service.get_kospi_symbols()
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting KOSPI symbols: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/kosdaq", response_model=List[str])
async def get_kosdaq_symbols():
    """Get all KOSDAQ stock ticker codes."""
    try:
        if not dependencies.kr_data_service:
            raise HTTPException(status_code=503, detail="Korean data service not available")

        return dependencies.kr_data_service.get_kosdaq_symbols()
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting KOSDAQ symbols: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/stock/{ticker}", response_model=dict)
async def get_stock_data(
    ticker: str,
    days: int = Query(default=30, ge=1, le=365, description="Number of days of history")
):
    """
    Get historical OHLCV data for a Korean stock.

    Args:
        ticker: Stock ticker code (e.g., "005930" for Samsung Electronics)
        days: Number of days of history (default: 30)
    """
    try:
        if not dependencies.kr_data_service:
            raise HTTPException(status_code=503, detail="Korean data service not available")

        df = await dependencies.kr_data_service.get_stock_data(ticker, days)

        if df is None or df.empty:
            raise HTTPException(status_code=404, detail=f"No data found for ticker: {ticker}")

        # Get stock info
        symbols = dependencies.kr_data_service.get_all_symbols()
        stock_info = symbols.get(ticker, {"name": "Unknown", "market": "Unknown"})

        return {
            "ticker": ticker,
            "name": stock_info["name"],
            "market": stock_info["market"],
            "days": days,
            "data": df.reset_index().to_dict(orient="records")
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting stock data for {ticker}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/price/{ticker}", response_model=StockPrice)
async def get_current_price(ticker: str):
    """
    Get current price for a Korean stock.

    Args:
        ticker: Stock ticker code (e.g., "005930" for Samsung Electronics)
    """
    try:
        if not dependencies.kr_data_service:
            raise HTTPException(status_code=503, detail="Korean data service not available")

        price = await dependencies.kr_data_service.get_current_price(ticker)

        if not price:
            raise HTTPException(status_code=404, detail=f"No price data for ticker: {ticker}")

        return StockPrice(**price)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting price for {ticker}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/top/kospi", response_model=List[MarketCapStock])
async def get_kospi_top_stocks(
    top_n: int = Query(default=50, ge=1, le=200, description="Number of top stocks")
):
    """Get top KOSPI stocks by market cap."""
    try:
        if not dependencies.kr_data_service:
            raise HTTPException(status_code=503, detail="Korean data service not available")

        return await dependencies.kr_data_service.get_market_cap_top("KOSPI", top_n)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting KOSPI top stocks: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/top/kosdaq", response_model=List[MarketCapStock])
async def get_kosdaq_top_stocks(
    top_n: int = Query(default=50, ge=1, le=200, description="Number of top stocks")
):
    """Get top KOSDAQ stocks by market cap."""
    try:
        if not dependencies.kr_data_service:
            raise HTTPException(status_code=503, detail="Korean data service not available")

        return await dependencies.kr_data_service.get_market_cap_top("KOSDAQ", top_n)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting KOSDAQ top stocks: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/search", response_model=List[StockInfo])
async def search_stocks(
    q: str = Query(..., min_length=1, description="Search query (name or ticker)")
):
    """
    Search Korean stocks by name or ticker code.

    Examples:
    - /kr/search?q=삼성
    - /kr/search?q=005930
    - /kr/search?q=카카오
    """
    try:
        if not dependencies.kr_data_service:
            raise HTTPException(status_code=503, detail="Korean data service not available")

        results = await dependencies.kr_data_service.search_stock(q)
        return [StockInfo(**r) for r in results]
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error searching stocks: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/market-summary")
async def get_market_summary():
    """Get summary of Korean market (KOSPI and KOSDAQ)."""
    try:
        if not dependencies.kr_data_service:
            raise HTTPException(status_code=503, detail="Korean data service not available")

        symbols = dependencies.kr_data_service.get_all_symbols()
        kospi_top = await dependencies.kr_data_service.get_market_cap_top("KOSPI", 10)
        kosdaq_top = await dependencies.kr_data_service.get_market_cap_top("KOSDAQ", 10)

        return {
            "total_symbols": len(symbols),
            "kospi": {
                "count": len([s for s in symbols.values() if s["market"] == "KOSPI"]),
                "top_10": kospi_top
            },
            "kosdaq": {
                "count": len([s for s in symbols.values() if s["market"] == "KOSDAQ"]),
                "top_10": kosdaq_top
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting market summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))
